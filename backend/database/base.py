# This file will hold the Base for SQLAlchemy models and all model definitions.
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from sqlalchemy import (Boolean, Column, DateTime, Float, ForeignKey, Integer,
                        String, Text, Table, func)
import uuid

Base = declarative_base()

# Many-to-many association table for solutions and knowledge
solution_references_knowledge = Table(
    'solution_references_knowledge',
    Base.metadata,
    Column('solution_id', String(255), ForeignKey('solutions.solution_id'), primary_key=True),
    Column('knowledge_id', String(255), ForeignKey('knowledge.knowledge_id'), primary_key=True)
)

class User(Base):
    __tablename__ = "users"
    user_id = Column(String(255), primary_key=True, default=lambda: str(uuid.uuid4()))
    username = Column(String(255), unique=True, index=True, nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    register_date = Column(DateTime, server_default=func.now())

    questions = relationship("Question", back_populates="owner")
    feedbacks = relationship("Feedback", back_populates="owner")

class Protocol(Base):
    __tablename__ = "protocols"
    protocol_id = Column(String(255), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String(255), nullable=False, comment="協定名稱, 例如: BGP, OSPF")
    rfc_number = Column(String(255), comment="相關的 RFC 文件編號")

    knowledge_entries = relationship("Knowledge", back_populates="protocol")

class Knowledge(Base):
    __tablename__ = "knowledge"
    knowledge_id = Column(String(255), primary_key=True, default=lambda: str(uuid.uuid4()))
    protocol_id = Column(String(255), ForeignKey("protocols.protocol_id"), nullable=True)
    content = Column(Text, nullable=False)
    source = Column(String(2048), nullable=True, comment="知識來源, 如文件名或網址")
    update_time = Column(DateTime, server_default=func.now(), onupdate=func.now())

    protocol = relationship("Protocol", back_populates="knowledge_entries")
    referenced_by_solutions = relationship(
        "Solution",
        secondary=solution_references_knowledge,
        back_populates="references_knowledge"
    )

class Question(Base):
    __tablename__ = "questions"
    question_id = Column(String(255), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(255), ForeignKey("users.user_id"), nullable=False)
    content = Column(Text, nullable=False)
    image_url = Column(String(2048), nullable=True)
    file_url = Column(String(2048), nullable=True, comment="附件文件的存储路径")
    file_name = Column(String(255), nullable=True, comment="附件文件的原始名称")
    ask_time = Column(DateTime, server_default=func.now())

    owner = relationship("User", back_populates="questions")
    solution = relationship("Solution", uselist=False, back_populates="question")

class Solution(Base):
    __tablename__ = "solutions"
    solution_id = Column(String(255), primary_key=True, default=lambda: str(uuid.uuid4()))
    question_id = Column(String(255), ForeignKey("questions.question_id"), nullable=False, unique=True)
    steps = Column(Text, nullable=True, comment="分步解決方案的內容")
    confidence_score = Column(Float, nullable=True, comment="系統對解決方案準確性的置信度評分 (0.0 - 1.0)")

    question = relationship("Question", back_populates="solution")
    feedbacks = relationship("Feedback", back_populates="solution")
    references_knowledge = relationship(
        "Knowledge",
        secondary=solution_references_knowledge,
        back_populates="referenced_by_solutions"
    )

class Feedback(Base):
    __tablename__ = "feedbacks"
    feedback_id = Column(String(255), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(255), ForeignKey("users.user_id"), nullable=False)
    solution_id = Column(String(255), ForeignKey("solutions.solution_id"), nullable=False)
    rating = Column(Integer, nullable=True, comment="使用者給出的評分")
    comment = Column(Text, nullable=True)
    
    owner = relationship("User", back_populates="feedbacks")
    solution = relationship("Solution", back_populates="feedbacks") 