from fastapi import FastAPI, Depends, HTTPException, status, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from datetime import timedelta
import tensorflow as tf
from PIL import Image
import numpy as np
import io
import os
import models, schemas, crud, auth, database
from routers import profile
from routers import history
from pathlib import Path
import shutil


# Créer les tables
models.Base.metadata.create_all(bind=database.engine)

app = FastAPI(
    title="Interior Design AI API",
    description="API complète pour classification et transformation de pièces",
    version="1.0.0"
)
app.include_router(profile.router)
app.include_router(history.router)
# Configuration CORS pour Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Charger le modèle de classification
MODEL_PATH = os.path.join("model", "room_classifier.keras")
try:
    classification_model = tf.keras.models.load_model(MODEL_PATH)
    print("✅ Modèle de classification chargé avec succès")
except Exception as e:
    print(f"❌ Erreur lors du chargement du modèle: {e}")
    classification_model = None

CLASS_NAMES = ["bathroom", "bedroom", "office", "kitchen", "living room"]
IMG_SIZE = 224

def preprocess_image(image_bytes: bytes):
    """Prépare l'image pour la classification"""
    img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    img = img.resize((IMG_SIZE, IMG_SIZE))
    arr = np.array(img).astype(np.float32) / 255.0
    arr = np.expand_dims(arr, axis=0)
    return arr

# ============= ENDPOINTS D'AUTHENTIFICATION =============

@app.post("/api/auth/register", response_model=schemas.Token, tags=["Authentication"])
async def register(user: schemas.UserCreate, db: Session = Depends(database.get_db)):
    """Inscription d'un nouvel utilisateur"""
    try:
        print(f"📝 Tentative d'inscription: {user.email}, {user.username}")
        
        # Vérifier si l'email existe déjà
        db_user = crud.get_user_by_email(db, email=user.email)
        if db_user:
            print(f"⚠️ Email déjà existant: {user.email}")
            raise HTTPException(
                status_code=400, 
                detail="Un compte avec cet email existe déjà"
            )
        
        # Vérifier si le username existe déjà
        db_user = crud.get_user_by_username(db, username=user.username)
        if db_user:
            print(f"⚠️ Username déjà existant: {user.username}")
            raise HTTPException(
                status_code=400,
                detail="Ce nom d'utilisateur est déjà pris"
            )
        
        print(f"🔐 Création de l'utilisateur...")
        # Créer l'utilisateur
        new_user = crud.create_user(db=db, user=user)
        print(f"✅ Utilisateur créé: ID={new_user.id}")
        
        print(f"🔑 Génération du token...")
        # Générer le token
        access_token = auth.create_access_token(
            data={"sub": new_user.email},
            expires_delta=timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
        )
        print(f"✅ Token généré")
        
        return {"access_token": access_token, "token_type": "bearer"}
    
    except HTTPException as he:
        print(f"❌ HTTPException: {he.detail}")
        raise
    except Exception as e:
        print(f"❌ ERREUR CRITIQUE: {type(e).__name__}: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=500,
            detail=f"Erreur serveur: {str(e)}"
        )
@app.post("/api/auth/login", response_model=schemas.Token, tags=["Authentication"])
def login(user: schemas.UserLogin, db: Session = Depends(database.get_db)):
    """Connexion utilisateur"""
    db_user = crud.authenticate_user(db, user.email, user.password)
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email ou mot de passe incorrect",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token = auth.create_access_token(
        data={"sub": db_user.email},
        expires_delta=timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/api/auth/me", response_model=schemas.User, tags=["Authentication"])
def get_current_user(
    token: str = Depends(auth.oauth2_scheme),
    db: Session = Depends(database.get_db)
):
    """Récupérer les informations de l'utilisateur connecté"""
    email = auth.verify_token(token)
    user = crud.get_user_by_email(db, email=email)
    if user is None:
        raise HTTPException(status_code=404, detail="Utilisateur non trouvé")
    return user

# ============= ENDPOINTS DE CLASSIFICATION =============

@app.post("/api/classify-room", tags=["Classification"])
async def classify_room_protected(
    file: UploadFile = File(...),
    token: str = Depends(auth.oauth2_scheme)
):
    """Classifier le type de pièce (authentification requise)"""
    # Vérifier le token
    auth.verify_token(token)
    
    if classification_model is None:
        raise HTTPException(
            status_code=500,
            detail="Le modèle de classification n'est pas disponible"
        )
    
    try:
        image_bytes = await file.read()
        img = preprocess_image(image_bytes)
        preds = classification_model.predict(img)
        class_index = int(np.argmax(preds))
        confidence = float(np.max(preds))

        return JSONResponse({
            "class": CLASS_NAMES[class_index],
            "confidence": round(confidence, 4),
            "all_predictions": {
                CLASS_NAMES[i]: round(float(preds[0][i]), 4)
                for i in range(len(CLASS_NAMES))
            }
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur: {str(e)}")

@app.post("/predict", tags=["Classification"])
async def predict_public(file: UploadFile = File(...)):
    """Endpoint public de classification (pour tests, sans authentification)"""
    if classification_model is None:
        raise HTTPException(
            status_code=500,
            detail="Le modèle de classification n'est pas disponible"
        )
    
    try:
        image_bytes = await file.read()
        img = preprocess_image(image_bytes)
        preds = classification_model.predict(img)
        class_index = int(np.argmax(preds))
        confidence = float(np.max(preds))

        return JSONResponse({
            "class": CLASS_NAMES[class_index],
            "confidence": round(confidence, 4)
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur: {str(e)}")

# ============= ENDPOINT DE TRANSFORMATION AI =============

@app.post("/api/transform-room", tags=["Transformation"])
async def transform_room(
    file: UploadFile = File(...),
    style: str = Form(...),
    room_type: str = Form(...),
    token: str = Depends(auth.oauth2_scheme),
    db: Session = Depends(database.get_db)  # ← AJOUTER db
):
    """Transformer une pièce avec le style demandé"""
    
    # Vérifier le token et récupérer l'utilisateur
    email = auth.verify_token(token)
    current_user = crud.get_user_by_email(db, email=email)
    
    if not current_user:
        raise HTTPException(status_code=404, detail="Utilisateur non trouvé")
    
    # Créer le dossier pour sauvegarder les images
    uploads_dir = Path("uploads/designs")
    uploads_dir.mkdir(parents=True, exist_ok=True)
    
    # Sauvegarder l'image originale
    timestamp = int(datetime.utcnow().timestamp())
    original_filename = f"original_{current_user.id}_{timestamp}.jpg"
    original_path = uploads_dir / original_filename
    
    # Lire et sauvegarder l'image
    image_data = await file.read()
    with original_path.open("wb") as f:
        f.write(image_data)
    
    # TODO: Intégrer votre modèle de transformation Stable Diffusion ici
    # Pour l'instant, on copie l'image originale comme "image générée"
    generated_filename = f"generated_{current_user.id}_{timestamp}.jpg"
    generated_path = uploads_dir / generated_filename
    
    # Temporaire : copier l'image originale
    import shutil
    shutil.copy(str(original_path), str(generated_path))
    
    # SAUVEGARDER DANS L'HISTORIQUE
    new_design = models.DesignHistory(
        user_id=current_user.id,
        original_image_path=str(original_path),
        generated_image_path=str(generated_path),
        room_type=room_type,
        style=style,
        confidence=None,  # Sera rempli après classification
        is_favorite=False
    )
    
    db.add(new_design)
    db.commit()
    db.refresh(new_design)
    
    return {
        "success": True,
        "message": "Design créé et sauvegardé",
        "design_id": new_design.id,
        "user_email": email,
        "style": style,
        "room_type": room_type,
        "original_image": str(original_path),
        "generated_image": str(generated_path)
    }

# ============= ENDPOINTS D'INFORMATION =============

@app.get("/", tags=["Info"])
def root():
    return {
        "message": "Interior Design AI API",
        "version": "1.0.0",
        "status": "running",
        "model_loaded": classification_model is not None,
        "endpoints": {
            "auth": [
                "POST /api/auth/register",
                "POST /api/auth/login",
                "GET /api/auth/me"
            ],
            "classification": [
                "POST /api/classify-room (protected)",
                "POST /predict (public)"
            ],
            "transformation": [
                "POST /api/transform-room (protected)"
            ]
        }
    }

@app.get("/health", tags=["Info"])
def health_check():
    return {
        "status": "healthy",
        "model_loaded": classification_model is not None
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)