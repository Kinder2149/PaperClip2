from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List, Optional
from app.db.database import get_db
from app.models.schemas import AnalyticsEventCreate, AnalyticsEvent, CrashReportCreate, CrashReport
from app.models.analytics import AnalyticsEvent as AnalyticsEventModel, CrashReport as CrashReportModel
from app.models.user import User
from app.auth.jwt import get_current_user
from app.services.analytics import AnalyticsService
from datetime import datetime, timedelta

router = APIRouter(prefix="/analytics", tags=["Analytics"])

# Initialiser le service d'analytique
analytics_service = AnalyticsService()

# Fonction pour traiter les événements en arrière-plan
def process_analytics_event(event_data: dict, user_id: Optional[str], db: Session):
    """Traite un événement d'analytique en arrière-plan"""
    analytics_service.log_event(
        db=db,
        event_name=event_data["event_name"],
        event_params=event_data["event_params"],
        user_id=user_id,
        session_id=event_data["session_id"],
        device_info=event_data.get("device_info"),
        app_version=event_data.get("app_version")
    )

@router.post("/events", response_model=AnalyticsEvent)
async def log_analytics_event(
    event_data: AnalyticsEventCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Enregistre un événement d'analytique pour l'utilisateur actuel"""
    # Traiter l'événement en arrière-plan pour ne pas bloquer la réponse
    background_tasks.add_task(
        process_analytics_event,
        event_data.dict(),
        current_user.id,
        db
    )
    
    # Créer un objet de réponse immédiate
    return {
        "id": "processing",
        "user_id": current_user.id,
        "event_name": event_data.event_name,
        "event_params": event_data.event_params,
        "session_id": event_data.session_id,
        "device_info": event_data.device_info,
        "app_version": event_data.app_version,
        "timestamp": datetime.utcnow()
    }

@router.post("/events/anonymous", response_model=AnalyticsEvent)
async def log_anonymous_analytics_event(
    event_data: AnalyticsEventCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """Enregistre un événement d'analytique anonyme (sans authentification)"""
    # Traiter l'événement en arrière-plan
    background_tasks.add_task(
        process_analytics_event,
        event_data.dict(),
        None,
        db
    )
    
    # Créer un objet de réponse immédiate
    return {
        "id": "processing",
        "user_id": None,
        "event_name": event_data.event_name,
        "event_params": event_data.event_params,
        "session_id": event_data.session_id,
        "device_info": event_data.device_info,
        "app_version": event_data.app_version,
        "timestamp": datetime.utcnow()
    }

# Fonction pour traiter les rapports de crash en arrière-plan
def process_crash_report(report_data: dict, user_id: Optional[str], db: Session):
    """Traite un rapport de crash en arrière-plan"""
    analytics_service.log_crash(
        db=db,
        error_message=report_data["error_message"],
        stack_trace=report_data["stack_trace"],
        user_id=user_id,
        device_info=report_data.get("device_info"),
        app_version=report_data.get("app_version"),
        additional_info=report_data.get("additional_info")
    )

@router.post("/crashes", response_model=CrashReport)
async def log_crash_report(
    report_data: CrashReportCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Enregistre un rapport de crash pour l'utilisateur actuel"""
    # Traiter le rapport en arrière-plan
    background_tasks.add_task(
        process_crash_report,
        report_data.dict(),
        current_user.id,
        db
    )
    
    # Créer un objet de réponse immédiate
    return {
        "id": "processing",
        "user_id": current_user.id,
        "error_message": report_data.error_message,
        "stack_trace": report_data.stack_trace,
        "device_info": report_data.device_info,
        "app_version": report_data.app_version,
        "additional_info": report_data.additional_info,
        "timestamp": datetime.utcnow()
    }

@router.post("/crashes/anonymous", response_model=CrashReport)
async def log_anonymous_crash_report(
    report_data: CrashReportCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """Enregistre un rapport de crash anonyme (sans authentification)"""
    # Traiter le rapport en arrière-plan
    background_tasks.add_task(
        process_crash_report,
        report_data.dict(),
        None,
        db
    )
    
    # Créer un objet de réponse immédiate
    return {
        "id": "processing",
        "user_id": None,
        "error_message": report_data.error_message,
        "stack_trace": report_data.stack_trace,
        "device_info": report_data.device_info,
        "app_version": report_data.app_version,
        "additional_info": report_data.additional_info,
        "timestamp": datetime.utcnow()
    }

@router.get("/stats")
async def get_analytics_stats(
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Récupère des statistiques d'analytique pour l'utilisateur actuel"""
    # Par défaut, récupérer les statistiques des 30 derniers jours
    if not start_date:
        start_date = datetime.utcnow() - timedelta(days=30)
    if not end_date:
        end_date = datetime.utcnow()
    
    # Récupérer les statistiques d'événements
    event_stats = analytics_service.get_event_stats(
        db=db,
        start_date=start_date,
        end_date=end_date,
        user_id=current_user.id
    )
    
    # Récupérer les statistiques de crashes
    crash_stats = analytics_service.get_crash_stats(
        db=db,
        start_date=start_date,
        end_date=end_date,
        user_id=current_user.id
    )
    
    return {
        "event_stats": event_stats,
        "crash_stats": crash_stats,
        "start_date": start_date,
        "end_date": end_date
    }
