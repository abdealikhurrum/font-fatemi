"""
Triggers the model-release GitHub Actions workflow after a successful FedAvg round.

Required environment variables:
    GITHUB_TOKEN       Personal access token with `repo` + `actions:write` scopes
    GITHUB_REPO        Owner/repo, e.g. "abdealikhurrum/font-fatemi"
    AGGREGATOR_URL     Public URL of this aggregator, e.g. "https://agg.example.com"
"""

import os
import logging
import requests

log = logging.getLogger("github_publisher")

GITHUB_API  = "https://api.github.com"
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN", "")
GITHUB_REPO  = os.getenv("GITHUB_REPO", "")
AGGREGATOR_URL = os.getenv("AGGREGATOR_URL", "")


def publish_model(version: str, contributors: int) -> bool:
    """
    Dispatch the model-release workflow for the given version.
    Returns True on success.
    """
    if not all([GITHUB_TOKEN, GITHUB_REPO, AGGREGATOR_URL]):
        log.warning(
            "GitHub publishing skipped — GITHUB_TOKEN / GITHUB_REPO / AGGREGATOR_URL not set"
        )
        return False

    url = f"{GITHUB_API}/repos/{GITHUB_REPO}/actions/workflows/model-release.yml/dispatches"
    resp = requests.post(
        url,
        headers={
            "Authorization": f"Bearer {GITHUB_TOKEN}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
        },
        json={
            "ref": "master",
            "inputs": {
                "version":        version,
                "aggregator_url": AGGREGATOR_URL,
                "contributors":   str(contributors),
            },
        },
        timeout=15,
    )

    if resp.status_code == 204:
        log.info("GitHub workflow dispatched for version %s", version)
        return True
    else:
        log.error("Workflow dispatch failed: %s %s", resp.status_code, resp.text)
        return False
