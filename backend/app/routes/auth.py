from fastapi import APIRouter, Depends, HTTPException, status, Body
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from app.db.database import get_db
from app.models.schemas import UserCreate, Token, UserLogin, RefreshTokenRequest, RefreshTokenResponse
from app.models.user import User
from app.auth.auth import (
    verify_password, get_password_hash, create_access_token, get_current_user,
    authenticate_user, create_user, authenticate_with_provider,
    change_password, reset_password_request, reset_password_confirm
)
# Utilisation des variables importées depuis jwt.py pour éviter les duplications
from app.auth.jwt import verify_refresh_token, create_refresh_token, SECRET_KEY, ALGORITHM

router = APIRouter(prefix="/auth", tags=["Authentication"])

# Endpoint de refresh token
@router.post("/refresh", response_model=RefreshTokenResponse)
async def refresh_token(
    refresh_request: RefreshTokenRequest = Body(...),
    db: Session = Depends(get_db)
):
    """Rafraîchit un access token expiré en utilisant un refresh token valide"""
    try:
        # Vérifier et décoder le refresh token
        token_data = verify_refresh_token(refresh_request.refresh_token)
        
        if token_data is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token de rafraîchissement invalide ou expiré",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # Vérifier l'existence de l'utilisateur
        user = db.query(User).filter(User.id == token_data.user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Utilisateur non trouvé",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # Générer un nouvel access token
        access_token, expires_at = create_access_token(
            data={"sub": user.id}
        )
        
        # Option: générer un nouveau refresh token pour la rotation des tokens
        # Décommenter pour activer cette fonctionnalité
        # new_refresh_token, _ = create_refresh_token(data={"sub": user.id})
        
        return {
            "access_token": access_token,
            "token_type": "bearer",
            # "refresh_token": new_refresh_token,  # Décommenter pour activer la rotation des refresh tokens
            "expires_at": expires_at
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Erreur lors du rafraîchissement du token: {str(e)}",
            headers={"WWW-Authenticate": "Bearer"},
        )

# Endpoints OAuth modernes
@router.post("/oauth/google")
async def oauth_google(
    provider_id: str,
    email: str,
    username: Optional[str] = None,
    profile_image_url: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """Endpoint OAuth moderne pour Google - Compatible avec Flutter"""
    # Utiliser le même service que le endpoint provider legacy
    user = authenticate_with_provider(
        db=db,
        provider="google",
        provider_id=provider_id,
        email=email,
        username=username,
        profile_image_url=profile_image_url
    )
    
    # Mettre à jour la date de dernière connexion
    user.last_login = datetime.utcnow()
    db.commit()
    
    # Générer un token JWT
    access_token = create_access_token(
        data={"sub": user.id}
    )
    
    # Calculer la date d'expiration
    expires_delta = timedelta(minutes=60 * 24 * 7)  # 7 jours
    expires_at = datetime.utcnow() + expires_delta
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user_id": user.id,
        "username": user.username,
        "expires_at": expires_at
    }

@router.post("/register", status_code=status.HTTP_201_CREATED)
async def register_user(user_data: UserCreate, db: Session = Depends(get_db)):
    """Enregistre un nouvel utilisateur dans le système"""
    try:
        # Utiliser le service d'authentification pour créer l'utilisateur
        new_user = create_user(
            db=db,
            email=user_data.email,
            password=user_data.password,
            username=user_data.username
        )
        
        # Générer un token JWT
        access_token = create_access_token(
            data={"sub": new_user.id}
        )
        
        # Calculer la date d'expiration
        expires_delta = timedelta(minutes=60 * 24 * 7)  # 7 jours
        expires_at = datetime.utcnow() + expires_delta
        
        return {
            "access_token": access_token,
            "token_type": "bearer",
            "user_id": new_user.id,
            "username": new_user.username,
            "expires_at": expires_at
        }
    except HTTPException as e:
        # Relancer l'exception
        raise e
    except Exception as e:
        # Gérer les autres erreurs
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erreur lors de l'enregistrement: {str(e)}"
        )

@router.post("/token", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    """Authentifie un utilisateur et retourne un token JWT"""
    # Utiliser le service d'authentification pour authentifier l'utilisateur
    user = authenticate_user(db, form_data.username, form_data.password)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email ou mot de passe incorrect",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Mettre à jour la date de dernière connexion
    user.last_login = datetime.utcnow()
    db.commit()
    
    # Générer un token JWT
    access_token, expires_at = create_access_token(
        data={"sub": user.id}
    )
    
    # Générer un refresh token
    refresh_token, _ = create_refresh_token(
        data={"sub": user.id}
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user_id": user.id,
        "username": user.username,
        "expires_at": expires_at,
        "refresh_token": refresh_token
    }

@router.post("/login", response_model=Token)
async def login_with_email(login_data: UserLogin, db: Session = Depends(get_db)):
    """Authentifie un utilisateur avec email/mot de passe et retourne un token JWT"""
    # Utiliser le service d'authentification pour authentifier l'utilisateur
    user = authenticate_user(db, login_data.email, login_data.password)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email ou mot de passe incorrect",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Mettre à jour la date de dernière connexion
    user.last_login = datetime.utcnow()
    db.commit()
    
    # Générer un token JWT
    access_token, expires_at = create_access_token(
        data={"sub": user.id}
    )
    
    # Générer un refresh token
    refresh_token, _ = create_refresh_token(
        data={"sub": user.id}
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user_id": user.id,
        "username": user.username,
        "expires_at": expires_at,
        "refresh_token": refresh_token
    }

@router.get("/me")
async def get_current_user_info(current_user: User = Depends(get_current_user)):
    """Retourne les informations de l'utilisateur actuellement authentifié"""
    return {
        "id": current_user.id,
        "email": current_user.email,
        "username": current_user.username,
        "profile_image_url": current_user.profile_image_url,
        "email_verified": current_user.email_verified,
        "provider": current_user.provider,
        "created_at": current_user.created_at,
        "last_login": current_user.last_login,
        "xp_total": current_user.xp_total,
        "level": current_user.level
    }

@router.post("/logout")
async def logout(current_user: User = Depends(get_current_user)):
    """Déconnecte l'utilisateur actuel (côté client)"""
    # Note: Avec JWT, la déconnexion est gérée côté client en supprimant le token
    # Cette route est fournie pour la compatibilité avec l'API Firebase
    # En production, on pourrait implémenter une liste noire de tokens
    return {"message": "Déconnexion réussie"}

@router.post("/change-password")
async def change_password_endpoint(
    current_password: str,
    new_password: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Change le mot de passe de l'utilisateur actuel"""
    # Utiliser le service d'authentification pour changer le mot de passe
    success = change_password(db, current_user.id, current_password, new_password)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Mot de passe actuel incorrect"
        )
    
    return {"message": "Mot de passe changé avec succès"}

@router.post("/provider")
async def login_with_provider(
    provider: str,
    provider_id: str,
    email: str,
    username: Optional[str] = None,
    profile_image_url: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """Authentifie un utilisateur avec un fournisseur tiers (Google, Apple, etc.)"""
    # Utiliser le service d'authentification pour authentifier avec un fournisseur
    user = authenticate_with_provider(
        db=db,
        provider=provider,
        provider_id=provider_id,
        email=email,
        username=username,
        profile_image_url=profile_image_url
    )
    
    # Mettre à jour la date de dernière connexion
    user.last_login = datetime.utcnow()
    db.commit()
    
    # Générer un token JWT
    access_token = create_access_token(
        data={"sub": user.id}
    )
    
    # Calculer la date d'expiration
    expires_delta = timedelta(minutes=60 * 24 * 7)  # 7 jours
    expires_at = datetime.utcnow() + expires_delta
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user_id": user.id,
        "username": user.username,
        "expires_at": expires_at
    }

@router.post("/verify-email/{token}")
async def verify_email_endpoint(token: str, db: Session = Depends(get_db)):
    """Vérifie l'email d'un utilisateur à partir d'un token de vérification"""
    try:
        # Décoder le token
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        token_type: str = payload.get("type")
        
        if user_id is None or token_type != "verify_email":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Token de vérification invalide"
            )
        
        # Récupérer l'utilisateur
        user = db.query(User).filter(User.id == user_id).first()
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Utilisateur non trouvé"
            )
        
        # Marquer l'email comme vérifié
        user.email_verified = True
        db.commit()
        
        return {"message": "Email vérifié avec succès"}
        
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Token de vérification invalide ou expiré"
        )

@router.post("/reset-password")
async def reset_password_request_endpoint(email: str, db: Session = Depends(get_db)):
    """Envoie un email de réinitialisation de mot de passe"""
    # Utiliser le service d'authentification pour créer une demande de réinitialisation
    reset_token = reset_password_request(db, email)
    
    if not reset_token:
        # Ne pas indiquer si l'email existe ou non pour des raisons de sécurité
        return {"message": "Si l'email existe, un lien de réinitialisation a été envoyé"}
    
    # En production, envoyez un email avec le lien de réinitialisation
    # Pour l'instant, retournons simplement le token pour les tests
    return {
        "message": "Un lien de réinitialisation a été envoyé",
        "reset_token": reset_token  # À supprimer en production
    }

@router.post("/reset-password/confirm")
async def reset_password_confirm_endpoint(token: str, new_password: str, db: Session = Depends(get_db)):
    """Réinitialise le mot de passe avec un token de réinitialisation"""
    # Utiliser le service d'authentification pour confirmer la réinitialisation
    success = reset_password_confirm(db, token, new_password)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Token de réinitialisation invalide ou expiré"
        )
    
    return {"message": "Mot de passe réinitialisé avec succès"}
