from sqlalchemy import Column, Integer, String, DateTime, Text, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from database import Base
from datetime import datetime


class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    username = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relation avec UserProfile
    profile = relationship("UserProfile", back_populates="user", uselist=False)
    designs = relationship("DesignHistory", back_populates="user")


class UserProfile(Base):
    __tablename__ = "user_profiles"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    bio = Column(Text, nullable=True)
    phone = Column(String, nullable=True)
    favorite_style = Column(String, nullable=True)
    profile_picture = Column(String, nullable=True)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relation avec User
    user = relationship("User", back_populates="profile", uselist=False)

class DesignHistory(Base):
    __tablename__ = "design_history"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    original_image_path = Column(String, nullable=False)  # Chemin de l'image originale
    generated_image_path = Column(String, nullable=False)  # Chemin de l'image générée
    room_type = Column(String, nullable=True)  # Type de pièce (bedroom, kitchen, etc.)
    style = Column(String, nullable=True)  # Style choisi (modern, minimalist, etc.)
    confidence = Column(String, nullable=True)  # Confiance de la classification
    is_favorite = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relation avec l'utilisateur
    user = relationship("User", back_populates="designs")
