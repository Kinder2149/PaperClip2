from pydantic import BaseModel, EmailStr, Field, validator
from typing import Optional, List, Dict, Any, Union
from datetime import datetime
import uuid

# Schémas pour l'authentification
class UserBase(BaseModel):
    email: EmailStr
    username: str

class UserCreate(UserBase):
    password: str
    
    @validator('password')
    def password_strength(cls, v):
        if len(v) < 8:
            raise ValueError('Le mot de passe doit contenir au moins 8 caractères')
        return v

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str
    user_id: str
    username: str
    expires_at: datetime
    refresh_token: Optional[str] = None

class RefreshTokenRequest(BaseModel):
    refresh_token: str
    
class RefreshTokenResponse(BaseModel):
    access_token: str
    token_type: str
    refresh_token: Optional[str] = None
    expires_at: datetime

class TokenData(BaseModel):
    user_id: Optional[str] = None
    
# Schémas pour les utilisateurs
class UserProfile(UserBase):
    id: str
    profile_image_url: Optional[str] = None
    is_active: bool
    created_at: datetime
    email_verified: bool
    provider: str
    xp_total: int
    level: int
    games_played: int
    highest_score: int
    
    class Config:
        orm_mode = True

class UserProfileUpdate(BaseModel):
    username: Optional[str] = None
    profile_image_url: Optional[str] = None
    
# Schémas pour les sauvegardes de jeu
class GameSaveBase(BaseModel):
    name: str
    data: str
    version: str
    is_auto_save: Optional[bool] = False
    device_info: Optional[str] = None
    play_time: Optional[int] = 0
    level: Optional[int] = 1
    metal: Optional[int] = 0
    clips_produced: Optional[int] = 0

class GameSaveCreate(GameSaveBase):
    pass

class GameSave(GameSaveBase):
    id: str
    user_id: str
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        orm_mode = True
        
# Schémas pour les sauvegardes de profil utilisateur
class UserProfileSaveCreate(BaseModel):
    save_id: str
    game_mode: str
    save_metadata: Optional[Dict[str, Any]] = {}
    
class UserProfileSaveResponse(BaseModel):
    id: str
    user_id: str
    save_id: str
    game_mode: str
    created_at: datetime
    updated_at: Optional[datetime] = None
    save_metadata: Optional[Dict[str, Any]] = {}
    
    class Config:
        orm_mode = True

# Schémas pour les événements d'analytique
class AnalyticsEventCreate(BaseModel):
    event_name: str
    event_params: Optional[Dict[str, Any]] = None
    session_id: str
    device_info: Optional[str] = None
    app_version: Optional[str] = None

class AnalyticsEvent(AnalyticsEventCreate):
    id: str
    user_id: Optional[str] = None
    timestamp: datetime
    
    class Config:
        orm_mode = True

class CrashReportCreate(BaseModel):
    error_message: str
    stack_trace: str
    device_info: Optional[str] = None
    app_version: Optional[str] = None
    additional_info: Optional[Dict[str, Any]] = None

class CrashReport(CrashReportCreate):
    id: str
    user_id: Optional[str] = None
    timestamp: datetime
    
    class Config:
        orm_mode = True

# Schémas pour la configuration à distance
class RemoteConfigCreate(BaseModel):
    key: str
    value: Dict[str, Any]
    description: Optional[str] = None
    is_active: Optional[bool] = True
    version: Optional[str] = "1.0.0"
    condition: Optional[str] = None

class RemoteConfig(RemoteConfigCreate):
    id: str
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        orm_mode = True

class ConfigVersionCreate(BaseModel):
    version_number: str
    config_snapshot: Dict[str, Any]
    notes: Optional[str] = None
    is_active: Optional[bool] = True

class ConfigVersion(ConfigVersionCreate):
    id: str
    published_at: datetime
    
    class Config:
        orm_mode = True

# Schémas pour les fonctionnalités sociales
class FriendRequestCreate(BaseModel):
    receiver_id: str

class FriendRequest(BaseModel):
    id: str
    sender_id: str
    receiver_id: str
    status: str
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        orm_mode = True

class FriendRequestUpdate(BaseModel):
    status: str  # accepted, rejected

class LeaderboardCreate(BaseModel):
    name: str
    description: Optional[str] = None
    is_active: Optional[bool] = True

class Leaderboard(LeaderboardCreate):
    id: str
    created_at: datetime
    
    class Config:
        orm_mode = True

class LeaderboardEntryCreate(BaseModel):
    leaderboard_id: str
    score: int

class LeaderboardEntry(LeaderboardEntryCreate):
    id: str
    user_id: str
    rank: Optional[int] = None
    timestamp: datetime
    
    class Config:
        orm_mode = True

class AchievementCreate(BaseModel):
    name: str
    description: str
    icon_url: Optional[str] = None
    points: Optional[int] = 0
    is_active: Optional[bool] = True

class Achievement(AchievementCreate):
    id: str
    
    class Config:
        orm_mode = True

class UserAchievementCreate(BaseModel):
    achievement_id: str

class UserAchievement(UserAchievementCreate):
    id: str
    user_id: str
    unlocked_at: datetime
    
    class Config:
        orm_mode = True
