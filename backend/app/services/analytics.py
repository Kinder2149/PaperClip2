import json
import os
import logging
from datetime import datetime
from typing import Dict, Any, Optional
from sqlalchemy.orm import Session
from app.models.analytics import AnalyticsEvent, CrashReport
from dotenv import load_dotenv

# Chargement des variables d'environnement
load_dotenv()

# Configuration du logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("analytics")

# Configuration des fichiers de log
LOG_DIR = os.getenv("LOG_DIR", "./logs")
os.makedirs(LOG_DIR, exist_ok=True)
os.makedirs(os.path.join(LOG_DIR, "events"), exist_ok=True)
os.makedirs(os.path.join(LOG_DIR, "crashes"), exist_ok=True)

class AnalyticsService:
    """Service pour gérer les événements d'analytique et les rapports de crash"""
    
    @staticmethod
    def log_event(
        db: Session,
        event_name: str,
        event_params: Optional[Dict[str, Any]] = None,
        user_id: Optional[str] = None,
        session_id: Optional[str] = None,
        device_info: Optional[str] = None,
        app_version: Optional[str] = None
    ) -> AnalyticsEvent:
        """
        Enregistre un événement d'analytique
        
        Args:
            db: Session de base de données
            event_name: Nom de l'événement
            event_params: Paramètres de l'événement
            user_id: ID de l'utilisateur (optionnel)
            session_id: ID de session (optionnel)
            device_info: Informations sur l'appareil (optionnel)
            app_version: Version de l'application (optionnel)
            
        Returns:
            L'événement créé
        """
        # Créer l'événement dans la base de données
        event = AnalyticsEvent(
            user_id=user_id,
            event_name=event_name,
            event_params=event_params or {},
            session_id=session_id,
            device_info=device_info,
            app_version=app_version
        )
        
        db.add(event)
        db.commit()
        db.refresh(event)
        
        # Enregistrer l'événement dans un fichier de log
        timestamp = datetime.utcnow().strftime("%Y%m%d")
        log_file = os.path.join(LOG_DIR, "events", f"events_{timestamp}.log")
        
        log_entry = {
            "id": event.id,
            "timestamp": event.timestamp.isoformat(),
            "event_name": event.event_name,
            "event_params": event.event_params,
            "user_id": event.user_id,
            "session_id": event.session_id,
            "device_info": event.device_info,
            "app_version": event.app_version
        }
        
        with open(log_file, "a") as f:
            f.write(json.dumps(log_entry) + "\n")
        
        return event
    
    @staticmethod
    def log_crash(
        db: Session,
        error_message: str,
        stack_trace: str,
        user_id: Optional[str] = None,
        device_info: Optional[str] = None,
        app_version: Optional[str] = None,
        additional_info: Optional[Dict[str, Any]] = None
    ) -> CrashReport:
        """
        Enregistre un rapport de crash
        
        Args:
            db: Session de base de données
            error_message: Message d'erreur
            stack_trace: Trace de la pile d'appels
            user_id: ID de l'utilisateur (optionnel)
            device_info: Informations sur l'appareil (optionnel)
            app_version: Version de l'application (optionnel)
            additional_info: Informations supplémentaires (optionnel)
            
        Returns:
            Le rapport de crash créé
        """
        # Créer le rapport de crash dans la base de données
        crash_report = CrashReport(
            user_id=user_id,
            error_message=error_message,
            stack_trace=stack_trace,
            device_info=device_info,
            app_version=app_version,
            additional_info=additional_info or {}
        )
        
        db.add(crash_report)
        db.commit()
        db.refresh(crash_report)
        
        # Enregistrer le rapport dans un fichier de log
        timestamp = datetime.utcnow().strftime("%Y%m%d")
        log_file = os.path.join(LOG_DIR, "crashes", f"crashes_{timestamp}.log")
        
        log_entry = {
            "id": crash_report.id,
            "timestamp": crash_report.timestamp.isoformat(),
            "error_message": crash_report.error_message,
            "stack_trace": crash_report.stack_trace,
            "user_id": crash_report.user_id,
            "device_info": crash_report.device_info,
            "app_version": crash_report.app_version,
            "additional_info": crash_report.additional_info
        }
        
        with open(log_file, "a") as f:
            f.write(json.dumps(log_entry) + "\n")
        
        # Logger l'erreur
        logger.error(f"CRASH: {error_message} - User: {user_id} - App: {app_version}")
        
        return crash_report
    
    @staticmethod
    def get_event_stats(
        db: Session,
        start_date: datetime,
        end_date: datetime,
        user_id: Optional[str] = None,
        event_name: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Récupère des statistiques sur les événements
        
        Args:
            db: Session de base de données
            start_date: Date de début
            end_date: Date de fin
            user_id: ID de l'utilisateur (optionnel)
            event_name: Nom de l'événement (optionnel)
            
        Returns:
            Statistiques sur les événements
        """
        # Construire la requête de base
        query = db.query(AnalyticsEvent).filter(
            AnalyticsEvent.timestamp >= start_date,
            AnalyticsEvent.timestamp <= end_date
        )
        
        # Filtrer par utilisateur si spécifié
        if user_id:
            query = query.filter(AnalyticsEvent.user_id == user_id)
        
        # Filtrer par nom d'événement si spécifié
        if event_name:
            query = query.filter(AnalyticsEvent.event_name == event_name)
        
        # Exécuter la requête
        events = query.all()
        
        # Calculer les statistiques
        event_counts = {}
        for event in events:
            if event.event_name not in event_counts:
                event_counts[event.event_name] = 0
            event_counts[event.event_name] += 1
        
        # Calculer les statistiques par utilisateur
        user_stats = {}
        for event in events:
            if event.user_id:
                if event.user_id not in user_stats:
                    user_stats[event.user_id] = {"event_count": 0, "events": {}}
                
                user_stats[event.user_id]["event_count"] += 1
                
                if event.event_name not in user_stats[event.user_id]["events"]:
                    user_stats[event.user_id]["events"][event.event_name] = 0
                
                user_stats[event.user_id]["events"][event.event_name] += 1
        
        return {
            "total_events": len(events),
            "event_counts": event_counts,
            "user_stats": user_stats,
            "start_date": start_date,
            "end_date": end_date
        }
    
    @staticmethod
    def get_crash_stats(
        db: Session,
        start_date: datetime,
        end_date: datetime,
        user_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Récupère des statistiques sur les crashes
        
        Args:
            db: Session de base de données
            start_date: Date de début
            end_date: Date de fin
            user_id: ID de l'utilisateur (optionnel)
            
        Returns:
            Statistiques sur les crashes
        """
        # Construire la requête de base
        query = db.query(CrashReport).filter(
            CrashReport.timestamp >= start_date,
            CrashReport.timestamp <= end_date
        )
        
        # Filtrer par utilisateur si spécifié
        if user_id:
            query = query.filter(CrashReport.user_id == user_id)
        
        # Exécuter la requête
        crashes = query.all()
        
        # Calculer les statistiques
        error_counts = {}
        for crash in crashes:
            if crash.error_message not in error_counts:
                error_counts[crash.error_message] = 0
            error_counts[crash.error_message] += 1
        
        # Calculer les statistiques par version
        version_stats = {}
        for crash in crashes:
            if crash.app_version:
                if crash.app_version not in version_stats:
                    version_stats[crash.app_version] = 0
                version_stats[crash.app_version] += 1
        
        return {
            "total_crashes": len(crashes),
            "error_counts": error_counts,
            "version_stats": version_stats,
            "start_date": start_date,
            "end_date": end_date
        }
