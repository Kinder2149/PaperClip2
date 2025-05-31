from sqlalchemy import Column, String, DateTime, Integer, ForeignKey, Boolean, Table
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.db.database import Base
import uuid

# Table d'association pour les relations d'amitié
friendship = Table(
    "friendships",
    Base.metadata,
    Column("user_id", String, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
    Column("friend_id", String, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
    Column("created_at", DateTime(timezone=True), server_default=func.now()),
    Column("status", String, default="pending")  # pending, accepted, blocked
)

class FriendRequest(Base):
    """Modèle pour les demandes d'amitié"""
    __tablename__ = "friend_requests"
    
    id = Column(String, primary_key=True, index=True, default=lambda: str(uuid.uuid4()))
    sender_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), index=True)
    receiver_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), index=True)
    status = Column(String, default="pending")  # pending, accepted, rejected
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relations
    sender = relationship("User", foreign_keys=[sender_id], backref="sent_requests")
    receiver = relationship("User", foreign_keys=[receiver_id], backref="received_requests")

class Leaderboard(Base):
    """Modèle pour les classements"""
    __tablename__ = "leaderboards"
    
    id = Column(String, primary_key=True, index=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, unique=True, index=True)
    description = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    is_active = Column(Boolean, default=True)

class LeaderboardEntry(Base):
    """Modèle pour les entrées de classement"""
    __tablename__ = "leaderboard_entries"
    
    id = Column(String, primary_key=True, index=True, default=lambda: str(uuid.uuid4()))
    leaderboard_id = Column(String, ForeignKey("leaderboards.id", ondelete="CASCADE"), index=True)
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), index=True)
    score = Column(Integer, default=0)
    rank = Column(Integer, nullable=True)
    timestamp = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relations
    leaderboard = relationship("Leaderboard", backref="entries")
    user = relationship("User", backref="leaderboard_entries")

class Achievement(Base):
    """Modèle pour les succès/réalisations"""
    __tablename__ = "achievements"
    
    id = Column(String, primary_key=True, index=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, unique=True, index=True)
    description = Column(String)
    icon_url = Column(String, nullable=True)
    points = Column(Integer, default=0)
    is_active = Column(Boolean, default=True)

class UserAchievement(Base):
    """Modèle pour les succès débloqués par les utilisateurs"""
    __tablename__ = "user_achievements"
    
    id = Column(String, primary_key=True, index=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), index=True)
    achievement_id = Column(String, ForeignKey("achievements.id", ondelete="CASCADE"), index=True)
    unlocked_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relations
    user = relationship("User", backref="achievements")
    achievement = relationship("Achievement", backref="users")
