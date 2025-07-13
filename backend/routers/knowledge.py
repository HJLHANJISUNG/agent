from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from .. import crud, schemas
from ..database.database import SessionLocal

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/knowledge/", response_model=schemas.Knowledge)
def create_knowledge(knowledge: schemas.KnowledgeCreate, db: Session = Depends(get_db)):
    # Optional: Check if protocol_id exists before creating
    if knowledge.protocol_id:
        db_protocol = crud.get_protocol(db, protocol_id=knowledge.protocol_id)
        if db_protocol is None:
            raise HTTPException(status_code=404, detail=f"Protocol with id {knowledge.protocol_id} not found")
    return crud.create_knowledge(db=db, knowledge=knowledge)

@router.get("/knowledge/{knowledge_id}", response_model=schemas.Knowledge)
def read_knowledge(knowledge_id: str, db: Session = Depends(get_db)):
    db_knowledge = crud.get_knowledge(db, knowledge_id=knowledge_id)
    if db_knowledge is None:
        raise HTTPException(status_code=404, detail="Knowledge not found")
    return db_knowledge 