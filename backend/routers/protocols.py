from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
import crud
import schemas
from database.database import SessionLocal

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/protocols/", response_model=schemas.Protocol)
def create_protocol(protocol: schemas.ProtocolCreate, db: Session = Depends(get_db)):
    return crud.create_protocol(db=db, protocol=protocol)

@router.get("/protocols/{protocol_id}", response_model=schemas.Protocol)
def read_protocol(protocol_id: str, db: Session = Depends(get_db)):
    db_protocol = crud.get_protocol(db, protocol_id=protocol_id)
    if db_protocol is None:
        raise HTTPException(status_code=404, detail="Protocol not found")
    return db_protocol 