import sys
import argparse
from datetime import datetime

from rich.console import Console
from rich.table import Table
from ray.job_submission import JobSubmissionClient, JobDetails, JobStatus

parser = argparse.ArgumentParser(description="List jobs on the Ray cluster")
parser.add_argument("--address", type=str, default="http://100.79.16.15:8265", help="Address to the cluster head.")
parser.add_argument(
    "--all_users", action="store_true", help="Enable this flag to view jobs from all users, not just your own."
)
parser.add_argument(
    "--all_statuses", action="store_true", help="Enable this flag to view finished jobs as well as running jobs."
)
parser.add_argument("--user_id", type=str, help="Your UT EID.")
parser.add_argument(
    "--check_id",
    type=str,
    default=None,
    help="Set this value to check if it is within the specified job filters (skip displaying table)",
)
args = parser.parse_args()

NULL_ENTRY = "N/A"
RUNNING_STATUS = [JobStatus.PENDING, JobStatus.RUNNING]


def list_filtered_jobs() -> list[JobDetails]:
    client = JobSubmissionClient(args.address)
    jobs = client.list_jobs()
    if not args.all_users:
        assert args.user_id is not None, "--user_id must have a value!"
        jobs = [job for job in jobs if (job.metadata is not None and job.metadata.get("user_id") == args.user_id)]
    if not args.all_statuses:
        jobs = [job for job in jobs if job.status in RUNNING_STATUS]
    return sorted(jobs, key=lambda job: job.start_time, reverse=True)


def unix_to_timestr(time: int | None) -> str:
    if time is None:
        return NULL_ENTRY
    return datetime.fromtimestamp(time / 1000).strftime("%Y-%m-%d %H:%M:%S")


def metadata_to_uid(metadata: dict | None) -> str:
    if metadata is None:
        return NULL_ENTRY
    return metadata.get("user_id", NULL_ENTRY)


def display_table(jobs: list[JobDetails]) -> None:
    console = Console()
    table = Table(title="Ray Jobs")

    table.add_column("Job ID", style="cyan", no_wrap=True)
    table.add_column("User", style="yellow")
    table.add_column("Start Time", style="blue")
    table.add_column("End Time", style="blue")
    table.add_column("Status", style="green")
    table.add_column("Entrypoint", style="magenta")

    for job in jobs:
        table.add_row(
            job.submission_id,
            metadata_to_uid(job.metadata),
            unix_to_timestr(job.start_time),
            unix_to_timestr(job.end_time),
            job.status,
            job.entrypoint,
        )

    console.print(table)


if __name__ == "__main__":
    jobs = list_filtered_jobs()
    if args.check_id:
        job_ids = [job.submission_id for job in jobs]
        sys.exit(args.check_id not in job_ids)
    display_table(jobs)
