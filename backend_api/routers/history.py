# backend_api/routers/history.py - NOUVEAU FICHIER

from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
import os
from pathlib import Path
import shutil

from database import get_db
from models import User, DesignHistory
from auth import get_current_user
from pydantic import BaseModel

router = APIRouter(prefix="/history", tags=["History"])

# Schémas Pydantic
class DesignHistoryResponse(BaseModel):
    id: int
    original_image_path: str
    generated_image_path: str
    room_type: Optional[str]
    style: Optional[str]
    confidence: Optional[str]
    is_favorite: bool
    created_at: datetime
    
    class Config:
        from_attributes = True


class SaveDesignRequest(BaseModel):
    original_image_path: str
    generated_image_path: str
    room_type: Optional[str] = None
    style: Optional[str] = None
    confidence: Optional[str] = None


# GET - Récupérer tout l'historique
@router.get("/all", response_model=List[DesignHistoryResponse])
async def get_all_history(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    limit: int = 50,
    offset: int = 0,
    favorites_only: bool = False
):
    """Récupère l'historique des designs de l'utilisateur"""
    
    query = db.query(DesignHistory).filter(
        DesignHistory.user_id == current_user.id
    )
    
    if favorites_only:
        query = query.filter(DesignHistory.is_favorite == True)
    
    history = query.order_by(
        DesignHistory.created_at.desc()
    ).offset(offset).limit(limit).all()
    
    return history


# GET - Récupérer un design spécifique
@router.get("/{design_id}", response_model=DesignHistoryResponse)
async def get_design_by_id(
    design_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Récupère un design spécifique par son ID"""
    
    design = db.query(DesignHistory).filter(
        DesignHistory.id == design_id,
        DesignHistory.user_id == current_user.id
    ).first()
    
    if not design:
        raise HTTPException(
            status_code=404,
            detail="Design not found"
        )
    
    return design


# POST - Sauvegarder un nouveau design
@router.post("/save")
async def save_design(
    original_image: UploadFile = File(...),
    generated_image: UploadFile = File(...),
    room_type: Optional[str] = Form(None),
    style: Optional[str] = Form(None),
    confidence: Optional[str] = Form(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Sauvegarde un nouveau design dans l'historique avec les images"""
    
    # Créer le dossier pour sauvegarder les images
    uploads_dir = Path("uploads/designs")
    uploads_dir.mkdir(parents=True, exist_ok=True)
    
    # Générer des noms de fichiers uniques
    timestamp = int(datetime.utcnow().timestamp())
    original_filename = f"original_{current_user.id}_{timestamp}.jpg"
    generated_filename = f"generated_{current_user.id}_{timestamp}.jpg"
    
    original_path = uploads_dir / original_filename
    generated_path = uploads_dir / generated_filename
    
    try:
        # Sauvegarder l'image originale
        with original_path.open("wb") as buffer:
            shutil.copyfileobj(original_image.file, buffer)
        
        # Sauvegarder l'image générée
        with generated_path.open("wb") as buffer:
            shutil.copyfileobj(generated_image.file, buffer)
        
        # Sauvegarder dans la base de données
        # Normalize paths to use forward slashes for URL compatibility (Windows uses backslashes)
        original_path_str = str(original_path).replace('\\', '/')
        generated_path_str = str(generated_path).replace('\\', '/')
        
        new_design = DesignHistory(
            user_id=current_user.id,
            original_image_path=original_path_str,
            generated_image_path=generated_path_str,
            room_type=room_type,
            style=style,
            confidence=confidence,
            is_favorite=False,
            created_at=datetime.utcnow()
        )
        
        db.add(new_design)
        db.commit()
        db.refresh(new_design)
        
        return {
            "message": "Design saved successfully",
            "design_id": new_design.id,
            "design": new_design
        }
    except Exception as e:
        # Nettoyer les fichiers en cas d'erreur
        if original_path.exists():
            os.remove(original_path)
        if generated_path.exists():
            os.remove(generated_path)
        raise HTTPException(status_code=500, detail=f"Error saving design: {str(e)}")


# PUT - Marquer/Démarquer comme favori
@router.put("/{design_id}/favorite")
async def toggle_favorite(
    design_id: int,
    is_favorite: bool,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Marque ou démarque un design comme favori"""
    
    design = db.query(DesignHistory).filter(
        DesignHistory.id == design_id,
        DesignHistory.user_id == current_user.id
    ).first()
    
    if not design:
        raise HTTPException(
            status_code=404,
            detail="Design not found"
        )
    
    design.is_favorite = is_favorite
    db.commit()
    db.refresh(design)
    
    return {
        "message": f"Design {'added to' if is_favorite else 'removed from'} favorites",
        "design": design
    }


# DELETE - Supprimer un design
@router.delete("/{design_id}")
async def delete_design(
    design_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Supprime un design de l'historique"""
    
    design = db.query(DesignHistory).filter(
        DesignHistory.id == design_id,
        DesignHistory.user_id == current_user.id
    ).first()
    
    if not design:
        raise HTTPException(
            status_code=404,
            detail="Design not found"
        )
    
    # Supprimer les fichiers images si nécessaire
    # (Optionnel - à activer si vous voulez supprimer les fichiers physiques)
    # if os.path.exists(design.original_image_path):
    #     os.remove(design.original_image_path)
    # if os.path.exists(design.generated_image_path):
    #     os.remove(design.generated_image_path)
    
    db.delete(design)
    db.commit()
    
    return {"message": "Design deleted successfully"}


# GET - Statistiques de l'utilisateur
@router.get("/stats/summary")
async def get_user_stats(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Récupère les statistiques de l'utilisateur"""
    
    total_designs = db.query(DesignHistory).filter(
        DesignHistory.user_id == current_user.id
    ).count()
    
    total_favorites = db.query(DesignHistory).filter(
        DesignHistory.user_id == current_user.id,
        DesignHistory.is_favorite == True
    ).count()
    
    # Styles les plus utilisés
    from sqlalchemy import func
    style_stats = db.query(
        DesignHistory.style,
        func.count(DesignHistory.style).label('count')
    ).filter(
        DesignHistory.user_id == current_user.id,
        DesignHistory.style.isnot(None)
    ).group_by(DesignHistory.style).all()
    
    # Room types les plus utilisés
    room_stats = db.query(
        DesignHistory.room_type,
        func.count(DesignHistory.room_type).label('count')
    ).filter(
        DesignHistory.user_id == current_user.id,
        DesignHistory.room_type.isnot(None)
    ).group_by(DesignHistory.room_type).all()
    
    return {
        "total_designs": total_designs,
        "total_favorites": total_favorites,
        "style_distribution": [{"style": s[0], "count": s[1]} for s in style_stats],
        "room_distribution": [{"room_type": r[0], "count": r[1]} for r in room_stats]
    }


# GET - Télécharger une image
@router.get("/download/{design_id}/{image_type}")
async def download_image(
    design_id: int,
    image_type: str,  # "original" ou "generated"
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Télécharge une image (originale ou générée)"""
    
    design = db.query(DesignHistory).filter(
        DesignHistory.id == design_id,
        DesignHistory.user_id == current_user.id
    ).first()
    
    if not design:
        raise HTTPException(
            status_code=404,
            detail="Design not found"
        )
    
    if image_type == "original":
        file_path = design.original_image_path
    elif image_type == "generated":
        file_path = design.generated_image_path
    else:
        raise HTTPException(
            status_code=400,
            detail="Invalid image type. Use 'original' or 'generated'"
        )
    
    if not os.path.exists(file_path):
        raise HTTPException(
            status_code=404,
            detail="Image file not found"
        )
    
    return FileResponse(
        file_path,
        media_type="image/jpeg",
        filename=f"design_{design_id}_{image_type}.jpg"
    )