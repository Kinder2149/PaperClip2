from sqlalchemy import Column, String, DateTime, JSON, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.db.database import Base
import uuid

class AnalyticsEvent(Base):
    """Modèle de données pour les événements d'analytique"""
    __tablename__ = "analytics_events"

    id = Column(String, primary_key=True, index=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    event_name = Column(String, index=True)
    event_params = Column(JSON, nullable=True)  # Paramètres de l'événement en JSON
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    session_id = Column(String, index=True)
    device_info = Column(String, nullable=True)
    app_version = Column(String, nullable=True)
    
    # Relation avec l'utilisateur
    user = relationship("User", backref="analytics_events")

class CrashReport(Base):
    """Modèle de données pour les rapports de crash (remplace Crashlytics)"""
    __tablename__ = "crash_reports"

    id = Column(String, primary_key=True, index=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    error_message = Column(String)
    stack_trace = Column(String)
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    device_info = Column(String, nullable=True)
    app_version = Column(String, nullable=True)
    additional_info = Column(JSON, nullable=True)
    
    # Relation avec l'utilisateur
    user = relationship("User", backref="crash_reports")
