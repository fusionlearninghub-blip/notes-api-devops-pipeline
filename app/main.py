"""
Notes API — a minimal service used as the deployment vehicle for the
CI/CD pipeline. The app is intentionally simple; the pipeline, infra,
and observability around it are the point of this project.
"""
from datetime import datetime, timezone
from uuid import uuid4
from typing import Optional

from fastapi import FastAPI, HTTPException, status
from pydantic import BaseModel
import os

app = FastAPI(
    title="Notes API",
    description="Sample service deployed via Terraform + ECS Fargate + GitHub Actions",
    version="1.0.0",
)

# In-memory store. Deliberately not a database — persistence isn't the
# point of this sample app, keeping the container stateless simplifies
# the ECS task design.
_notes: dict[str, dict] = {}


class NoteIn(BaseModel):
    title: str
    body: str


class NoteOut(NoteIn):
    id: str
    created_at: str


@app.get("/health")
def health():
    """Liveness/readiness probe target for the ALB health check."""
    return {"status": "healthy", "timestamp": datetime.now(timezone.utc).isoformat()}


@app.get("/version")
def version():
    return {
        "version": app.version,
        "git_sha": os.getenv("GIT_SHA", "unknown"),
        "environment": os.getenv("APP_ENV", "local"),
    }


@app.post("/notes", response_model=NoteOut, status_code=status.HTTP_201_CREATED)
def create_note(note: NoteIn):
    note_id = str(uuid4())
    record = {
        "id": note_id,
        "title": note.title,
        "body": note.body,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    _notes[note_id] = record
    return record


@app.get("/notes", response_model=list[NoteOut])
def list_notes():
    return list(_notes.values())


@app.get("/notes/{note_id}", response_model=NoteOut)
def get_note(note_id: str):
    note = _notes.get(note_id)
    if not note:
        raise HTTPException(status_code=404, detail="Note not found")
    return note


@app.delete("/notes/{note_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_note(note_id: str):
    if note_id not in _notes:
        raise HTTPException(status_code=404, detail="Note not found")
    del _notes[note_id]
