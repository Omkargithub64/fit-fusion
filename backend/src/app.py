from flask import Flask,request,jsonify,session
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import and_
import cloudinary
import cloudinary.uploader
from flask_login import LoginManager, UserMixin, login_user, login_required, current_user, logout_user
from datetime import datetime


from rembg import remove
from PIL import Image
import io


import os
import numpy as np
import tensorflow as tf
from tensorflow.keras.applications import EfficientNetB0
from tensorflow.keras.preprocessing import image
from tensorflow.keras.applications.efficientnet import preprocess_input
from tensorflow.keras.models import load_model


import base64
import wget 
from werkzeug.security import generate_password_hash,check_password_hash


app = Flask(__name__)
CORS(app)
UPLOAD_FOLDER = 'uploads'


app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['SECRET_KEY'] = 'my key'
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///users.db'
app.config['SESSION_TYPE'] = 'filesystem'
app.config['SESSION_COOKIE_HTTPONLY'] = True

db = SQLAlchemy(app)
login_manager = LoginManager(app)


cloudinary.config(
    cloud_name ='dfr9yu2mi',
    api_key='999488851942618',
    api_secret='-SbXYOVyMIKfSnrFj6SWFxlSoAQ'
)

CATEGORIES = ['top', 'bottom', 'shoes']
for category in CATEGORIES:
    category_folder = os.path.join(UPLOAD_FOLDER, category)
    if not os.path.exists(category_folder):
        os.makedirs(category_folder)





class User(UserMixin, db.Model):
    id = db.Column(db.Integer, primary_key = True)
    username = db.Column(db.String(150), unique = True, nullable=False)
    password = db.Column(db.String(150), nullable = False)
    tops = db.Column(db.String(300))
    bottoms = db.Column(db.String(300))
    shoes = db.Column(db.String(300))
    body_image = db.Column(db.String(300),default="https://res.cloudinary.com/dfr9yu2mi/image/upload/v1729089091/vmozo9o0fvfs6ao31dwm.png")
    

class Upload(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    category = db.Column(db.String(50), nullable=False)
    url = db.Column(db.String(300), nullable=False)


class UserImage(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    image_url = db.Column(db.String(300), nullable=False)
    likes = db.relationship('Likes', backref='user_image', lazy=True, cascade='all, delete-orphan')
    created_at = db.Column(db.DateTime, default=db.func.current_timestamp())

class Likes(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    image_id = db.Column(db.Integer, db.ForeignKey('user_image.id'), nullable=False)


class SavedOutfit(db.Model):
    __tablename__ = 'saved_outfit'  # Ensure explicit table naming
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    top = db.Column(db.String(300))
    bottom = db.Column(db.String(300))
    shoes = db.Column(db.String(300))
    created_at = db.Column(db.DateTime, default=db.func.current_timestamp())

    # Define a relationship with ScheduledOutfit using lazy loading to prevent circular references
    scheduled_outfits = db.relationship('ScheduledOutfit', backref='outfit', lazy=True)

class ScheduledOutfit(db.Model):
    __tablename__ = 'scheduled_outfit'  # Ensure explicit table naming
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    outfit_id = db.Column(db.Integer, db.ForeignKey('saved_outfit.id'), nullable=False)
    schedule_date = db.Column(db.DateTime, nullable=False)

    user = db.relationship('User', backref='scheduled_outfits', lazy=True)







@login_manager.user_loader
def load_user(user_id):
    return User.query.get(int(user_id))


@app.route('/register', methods=['POST'])
def register():
    username = request.json.get('username')
    password = request.json.get('password')

    if not username or not password:
        return jsonify({'message': 'username-and-password-required'}), 400
    
    if len(username) < 3 or len(username) > 20:
        return jsonify({'message': 'username-length-invalid'}), 400

    if len(password) < 8:
        return jsonify({'message': 'password-length-invalid'}), 400

    if User.query.filter_by(username=username).first():
        return jsonify({'message': 'username-exists'}), 400

    hashed_password = generate_password_hash(password)

    new_user = User(username=username, password=hashed_password)
    db.session.add(new_user)
    db.session.commit()

    return jsonify({'message': 'user-register-success'}), 201


@app.route('/login', methods=['POST'])
def login():
    username = request.json.get('username')
    password = request.json.get('password')
    
    if not username or not password:
        return jsonify({'message': 'username-and-password-required'}), 400

    user = User.query.filter_by(username=username).first()
    
    if user and check_password_hash(user.password, password):
        login_user(user)
        session['user_id'] = user.id
        return jsonify({'message': 'login-success'}), 200
    
    return jsonify({'message': 'invalid-creds'}), 401







@app.route('/upload', methods=['POST'])
@login_required
def upload():
    files = request.files
    upload_records = []

    def remove_background(image_file):
        input_image = Image.open(image_file)
        output_image = remove(input_image)
        output_buffer = io.BytesIO()
        output_image.save(output_buffer, format='PNG')
        output_buffer.seek(0)
        return output_buffer

    # Process and upload top image
    if 'top' in files and files['top'].filename != '':
        top_image = files['top']
        top_image_with_bg_removed = remove_background(top_image)
        top_result = cloudinary.uploader.upload(top_image_with_bg_removed, resource_type="image", format="png")
        upload_records.append(Upload(user_id=current_user.id, category='top', url=top_result['secure_url']))

    # Process and upload bottom image
    if 'bottom' in files and files['bottom'].filename != '':
        bottom_image = files['bottom']
        bottom_image_with_bg_removed = remove_background(bottom_image)
        bottom_result = cloudinary.uploader.upload(bottom_image_with_bg_removed, resource_type="image", format="png")
        upload_records.append(Upload(user_id=current_user.id, category='bottom', url=bottom_result['secure_url']))

    # Process and upload shoes image
    if 'shoes' in files and files['shoes'].filename != '':
        shoes_result = cloudinary.uploader.upload(files['shoes'])
        upload_records.append(Upload(user_id=current_user.id, category='shoes', url=shoes_result['secure_url']))

    # Save records in the database
    if upload_records:
        db.session.bulk_save_objects(upload_records)
        db.session.commit()
        return jsonify({'message': 'images-uploaded'}), 200
    else:
        return jsonify({'message': 'no-images-uploaded'}), 400


@app.route('/upload_body_image', methods=['POST'])
@login_required
def upload_body_image():
    if 'body_image' not in request.files:
        return jsonify({'message': 'no-image-uploaded'}), 400

    file = request.files['body_image']
    if file.filename == '':
        return jsonify({'message': 'no-image-uploaded'}), 400

    result = cloudinary.uploader.upload(file)
    body_image_url = result['secure_url']

    current_user.body_image = body_image_url
    db.session.commit()

    return jsonify({'message': 'body-image-uploaded', 'body_image_url': body_image_url}), 200


@app.route('/delete_cloth', methods=['POST'])
@login_required
def delete_cloth():
    data = request.json
    category = data.get('category')
    image_url = data.get('image_url')

    upload_record = Upload.query.filter_by(user_id=current_user.id, category=category, url=image_url).first()

    if not upload_record:
        return jsonify({"error": "Clothing item not found"}), 404
    
    try:
        cloudinary.uploader.destroy(upload_record.url.split('/')[-1].split('.')[0])
    except Exception as e:
        return jsonify({"error": f"Error deleting image from Cloudinary: {str(e)}"}), 500


    db.session.delete(upload_record)
    db.session.commit()

    return jsonify({"message": "Clothing item deleted successfully"}), 200



@app.route('/get_clothes', methods=['GET'])
@login_required
def get_clothes():
    uploads =  Upload.query.filter_by(user_id=current_user.id).all()
    
    clothes = {
        'top': [],
        'bottom': [],
        'shoes': [],
        'body_image': [current_user.body_image]
    }
    
    for upload in uploads:
        if upload.category in clothes:
            clothes[upload.category].append(upload.url)
    
    return jsonify(clothes)


@app.route('/get_model', methods=['GET'])
@login_required
def get_model_pic():
    
    return jsonify({"body_image":current_user.body_image})


@app.route('/upload_public_image', methods=['POST'])
@login_required
def upload_public_image():
    if 'image' not in request.files:
        return jsonify({'message': 'no-image-uploaded'}), 400

    file = request.files['image']
    if file.filename == '':
        return jsonify({'message': 'no-image-uploaded'}), 400

    result = cloudinary.uploader.upload(file)
    image_url = result['secure_url']

    user_image = UserImage(user_id=current_user.id, image_url=image_url)
    db.session.add(user_image)
    db.session.commit()

    return jsonify({'message': 'image-uploaded', 'image_url': image_url}), 201

@app.route('/like_image', methods=['POST'])
@login_required
def like_image():
    image_id = request.json.get('image_id')

    
    image = UserImage.query.get(image_id)
    if not image:
        return jsonify({'message': 'image-not-found'}), 404

    existing_like = Likes.query.filter_by(user_id=current_user.id, image_id=image_id).first()
    
    if existing_like:
        db.session.delete(existing_like)
        db.session.commit()
        return jsonify({'message': 'image-unliked'}), 200
    else:
        new_like = Likes(user_id=current_user.id, image_id=image_id)
        db.session.add(new_like)
        db.session.commit()
        return jsonify({'message': 'image-liked'}), 200
    
@app.route('/save_outfit', methods=['POST'])
@login_required
def save_outfit():
    data = request.json
    top = data.get('top')
    bottom = data.get('bottom')
    shoes = data.get('shoes')

    # Ensure at least one part of the outfit is provided
    if not top and not bottom and not shoes:
        return jsonify({'message': 'No outfit provided'}), 400

    saved_outfit = SavedOutfit(
        user_id=current_user.id,
        top=top,
        bottom=bottom,
        shoes=shoes
    )

    db.session.add(saved_outfit)
    db.session.commit()

    return jsonify({'message': 'Outfit saved successfully'}), 200


@app.route('/get_saved_outfits', methods=['GET'])
@login_required
def get_saved_outfits():
    saved_outfits = SavedOutfit.query.filter_by(user_id=current_user.id).all()
    outfit_list = [{
        'id': outfit.id,
        'top': outfit.top,
        'bottom': outfit.bottom,
        'shoes': outfit.shoes,
        'created_at': outfit.created_at
    } for outfit in saved_outfits]

    return jsonify(outfit_list), 200





    
@app.route('/get_public_images', methods=['GET'])
def get_public_images():
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 30, type=int)

    total_images = db.session.query(UserImage).count()

    images = db.session.query(
        UserImage.id, 
        UserImage.image_url, 
        UserImage.user_id, 
        User.username,
        db.func.count(Likes.id).label('like_count')
    ).outerjoin(Likes, Likes.image_id == UserImage.id) \
    .join(User, User.id == UserImage.user_id) \
    .group_by(UserImage.id, User.username) \
    .order_by(UserImage.id.desc()) \
    .limit(per_page).offset((page - 1) * per_page)


    image_list = [{
        'image_id': image.id,
        'image_url': image.image_url,
        'like_count': image.like_count,
        'user_id': image.user_id,
        'username': image.username
    } for image in images]

    return jsonify({
        'images': image_list,
        'total_images': total_images,
        'page': page,
        'per_page': per_page
    }), 200


@app.route('/get_leaderbord', methods=['GET'])
@login_required
def leaderbord():
    user_like_totals = db.session.query(
        User.id,
        User.username,
        db.func.count(Likes.id).label('total_likes')
    ).outerjoin(UserImage, User.id == UserImage.user_id) \
    .outerjoin(Likes, Likes.image_id == UserImage.id) \
    .group_by(User.id, User.username) \
    .order_by(db.func.count(Likes.id).desc()) \
    .all()

    ranked_users = [{
        'rank': rank + 1,
        'user_id': user.id,
        'username': user.username,
        'total_likes': user.total_likes
    } for rank, user in enumerate(user_like_totals)]

    current_user_rank = next((user['rank'] for user in ranked_users if user['user_id'] == current_user.id), None)
    current_user_total_likes = next((user['total_likes'] for user in ranked_users if user['user_id'] == current_user.id), 0)


    return jsonify({
        'top_users': ranked_users,
        'current_user_rank': current_user_rank,
        'current_user_total_likes': current_user_total_likes
    }), 200



@app.route('/profile', methods=['GET'])
@login_required
def profile():
    user = current_user
    total_likes = Likes.query.filter_by(user_id=user.id).count()
    uploads = UserImage.query.filter_by(user_id=user.id).all()

    user_uploads = [{"id": upload.id, "url": upload.image_url} for upload in uploads]

    return jsonify({
        'username': user.username,
        'total_likes': total_likes,
        'uploads': user_uploads
    }), 200



@app.route('/edit_profile', methods=['PUT'])
@login_required
def edit_profile():
    username = request.json.get('username')
    password = request.json.get('password')

    if username:
        # Check if the new username is taken
        if User.query.filter_by(username=username).first():
            return jsonify({'message': 'username-exists'}), 400
        current_user.username = username

    if password:
        if len(password) < 8:
            return jsonify({'message': 'password-length-invalid'}), 400
        current_user.password = generate_password_hash(password)

    db.session.commit()
    return jsonify({'message': 'profile-updated'}), 200

@app.route('/delete_post', methods=['DELETE'])
@login_required
def delete_post():
    # Get the post ID from the request
    post_id = request.json.get('post_id')

    # Find the UserImage object
    user_image = UserImage.query.filter_by(id=post_id).first()
    
    if not user_image:
        return jsonify({"error": "Post not found"}), 404

    # Delete the UserImage, which will also delete associated Likes due to the cascade option
    db.session.delete(user_image)
    db.session.commit()

    return jsonify({"message": "Post deleted successfully"}), 200



# DELETE Saved Outfit Route
@app.route('/delete_saved_outfit/<int:outfit_id>', methods=['DELETE'])
@login_required
def delete_saved_outfit(outfit_id):
    saved_outfit = SavedOutfit.query.filter_by(id=outfit_id, user_id=current_user.id).first()

    if not saved_outfit:
        return jsonify({'message': 'Saved outfit not found or you are not authorized to delete this outfit'}), 404

    db.session.delete(saved_outfit)
    db.session.commit()

    return jsonify({'message': 'Saved outfit deleted successfully'}), 200


from flask_login import current_user

@app.route('/schedule_outfit', methods=['POST'])
@login_required
def schedule_outfit():
    data = request.get_json()

    # Parse the input
    outfit_id = data.get('outfit_id')
    schedule_date_str = data.get('schedule_date')  # Assume this is in ISO format

    # Get user_id from current_user (Flask-Login)
    user_id = current_user.id

    # Convert schedule_date from string to datetime object
    try:
        schedule_date = datetime.fromisoformat(schedule_date_str)  # or datetime.strptime(schedule_date_str, '%Y-%m-%dT%H:%M:%S.%f')
    except ValueError as e:
        return jsonify({"error": "Invalid date format"}), 400

    # Create a new scheduled outfit instance
    new_scheduled_outfit = ScheduledOutfit(
        user_id=user_id,
        outfit_id=outfit_id,
        schedule_date=schedule_date
    )

    # Add and commit to the database
    try:
        db.session.add(new_scheduled_outfit)
        db.session.commit()
        return jsonify({"message": "Outfit scheduled successfully"}), 201
    except Exception as e:
        db.session.rollback()  # Rollback the session in case of error
        return jsonify({"error": str(e)}), 500

@app.route('/scheduled_outfits', methods=['GET'])
@login_required
def get_scheduled_outfits():
    user_id = current_user.id
    schedule_date_str = request.args.get('schedule_date')

    # Check if schedule_date is provided
    if not schedule_date_str:
        return jsonify({"error": "schedule_date is required"}), 400

    try:
        # Convert the date string to a datetime object
        schedule_date = datetime.strptime(schedule_date_str, '%Y-%m-%d')
    except ValueError:
        # Return error if the date format is invalid
        return jsonify({"error": "Invalid date format, expected YYYY-MM-DD"}), 400

    # Fetch outfits for the user on the specific date
    scheduled_outfits = ScheduledOutfit.query.filter(
        ScheduledOutfit.user_id == user_id,
        ScheduledOutfit.schedule_date == schedule_date
    ).all()

    # Prepare the response
    results = [
        {
            'outfit_id': outfit.outfit_id,
            'schedule_date': outfit.schedule_date.strftime('%Y-%m-%d'),
        } for outfit in scheduled_outfits
    ]

    # Debugging: Log the response
    print("Scheduled Outfits API Response:", results)

    return jsonify(results), 200

@app.route('/logout', methods=['POST'])
@login_required
def logout():
    logout_user()
    session.pop('user_id', None)
    return jsonify({'message': 'logout-success'}), 200











# deep learning part.......

CATEGORIES = ['top', 'bottom', 'shoes']
for category in CATEGORIES:
    category_folder = os.path.join(UPLOAD_FOLDER, category)
    if not os.path.exists(category_folder):
        os.makedirs(category_folder)

base_model = EfficientNetB0(weights='imagenet', include_top=False, input_shape=(224, 224, 3))


def extract_features(img_path):
    img = image.load_img(img_path, target_size=(224,224))
    img_data = image.img_to_array(img)
    img_data = np.expand_dims(img_data,axis=0)
    img_data = preprocess_input(img_data)

    features = base_model.predict(img_data)
    
    
    return features

comb_model = load_model('models/comb_model.h5')
score_model = load_model('models/outfit_scoring_model.h5')

def image_to_base64(img_path):
    with open(img_path, "rb") as img_file:
        return base64.b64encode(img_file.read()).decode('utf-8')


def download_image_from_cloudinary(image_url, category):
    category_folder = os.path.join(app.config['UPLOAD_FOLDER'], category)

    if not os.path.exists(category_folder):
        os.makedirs(category_folder)

    image_filename = os.path.basename(image_url)
    image_path = os.path.join(category_folder, image_filename)
    
    wget.download(image_url,image_path)
    # cloudinary.utils.download_archive_url()
    
    return image_path


@app.route('/generate', methods=['GET'])
@login_required
def generate():
    uploads = Upload.query.filter_by(user_id=current_user.id).all()

    if not uploads:
        return jsonify({"error": "No clothes found for this user"}), 400

    top_images = []
    bottom_images = []
    shoes_images = []

    for upload in uploads:
        if upload.category == 'top':
            top_images.append(upload.url)
        elif upload.category == 'bottom':
            bottom_images.append(upload.url)
        elif upload.category == 'shoes':
            shoes_images.append(upload.url)

    if not top_images or not bottom_images or not shoes_images:
        return jsonify({"error": "Not enough images for generating outfit"}), 400

    top_features = []
    bottom_features = []
    shoes_features = []
    
    downloaded_image_paths = []

    for img_url in top_images:
        img_path = download_image_from_cloudinary(img_url, 'top')
        top_features.append(extract_features(img_path))
        downloaded_image_paths.append(img_path)

    for img_url in bottom_images:
        img_path = download_image_from_cloudinary(img_url, 'bottom')
        bottom_features.append(extract_features(img_path))
        downloaded_image_paths.append(img_path)

    for img_url in shoes_images:
        img_path = download_image_from_cloudinary(img_url, 'shoes')
        shoes_features.append(extract_features(img_path))
        downloaded_image_paths.append(img_path)

    combinations = []
    scores = []
    for top_idx, top in enumerate(top_features):
        for bottom_idx, bottom in enumerate(bottom_features):
            for shoes_idx, shoes in enumerate(shoes_features):
                cnn_features = np.stack([top, bottom, shoes])
                cnn_features = cnn_features.reshape((1, 3, -1))

                prob = comb_model.predict(cnn_features)
                print(f"Top shape: {top.shape}, Bottom shape: {bottom.shape}, Shoes shape: {shoes.shape}")

                score = score_model.predict([top.reshape(1, -1), bottom.reshape(1, -1), shoes.reshape(1, -1)])
                scores.append(score)

                combinations.append({
                    "top_image_url": top_images[top_idx],       # Use URL instead of base64
                    "bottom_image_url": bottom_images[bottom_idx],  # Use URL instead of base64
                    "shoes_image_url": shoes_images[shoes_idx],     # Use URL instead of base64
                    "score": score.tolist()
                })

    combinations.sort(key=lambda x: x['score'][0], reverse=True)
    best_combinations = combinations[:2]

    for img_path in downloaded_image_paths:
        if os.path.exists(img_path):
            os.remove(img_path)

    return jsonify({
        "best_combinations": best_combinations
    })



@app.route('/recommend', methods=['POST'])
@login_required
def recommend():
    data = request.get_json()
    selected_category = data.get('category')  # e.g., 'top', 'bottom', or 'shoes'
    selected_image_url = data.get('image_url')  # URL of the selected image

    if not selected_category or not selected_image_url:
        return jsonify({"error": "Category and image URL must be provided"}), 400

    # Fetch all available images from the database
    uploads = Upload.query.filter_by(user_id=current_user.id).all()
    if not uploads:
        return jsonify({"error": "No clothes found for this user"}), 400

    # Separate the uploaded images into categories
    top_images = []
    bottom_images = []
    shoes_images = []

    for upload in uploads:
        if upload.category == 'top':
            top_images.append(upload.url)
        elif upload.category == 'bottom':
            bottom_images.append(upload.url)
        elif upload.category == 'shoes':
            shoes_images.append(upload.url)

    # Check the selected category and extract its features
    selected_features = extract_features(download_image_from_cloudinary(selected_image_url, selected_category))

    # Prepare empty lists for the other categories to recommend from
    if selected_category == 'top':
        if not bottom_images or not shoes_images:
            return jsonify({"error": "Not enough items to recommend an outfit"}), 400
        
        # Extract features for bottoms and shoes
        bottom_features = []
        shoes_features = []
        for img_url in bottom_images:
            bottom_features.append(extract_features(download_image_from_cloudinary(img_url, 'bottom')))
        for img_url in shoes_images:
            shoes_features.append(extract_features(download_image_from_cloudinary(img_url, 'shoes')))
        
        # Generate combinations
        combinations = []
        for bottom_idx, bottom in enumerate(bottom_features):
            for shoes_idx, shoes in enumerate(shoes_features):
                cnn_features = np.stack([selected_features, bottom, shoes])
                cnn_features = cnn_features.reshape((1, 3, -1))

                prob = comb_model.predict(cnn_features)
                score = score_model.predict([selected_features.reshape(1, -1), bottom.reshape(1, -1), shoes.reshape(1, -1)])

                combinations.append({
                    "top_image_url": selected_image_url,
                    "bottom_image_url": bottom_images[bottom_idx],
                    "shoes_image_url": shoes_images[shoes_idx],
                    "score": score.tolist()
                })

    elif selected_category == 'bottom':
        if not top_images or not shoes_images:
            return jsonify({"error": "Not enough items to recommend an outfit"}), 400
        
        top_features = []
        shoes_features = []
        for img_url in top_images:
            top_features.append(extract_features(download_image_from_cloudinary(img_url, 'top')))
        for img_url in shoes_images:
            shoes_features.append(extract_features(download_image_from_cloudinary(img_url, 'shoes')))
        
        combinations = []
        for top_idx, top in enumerate(top_features):
            for shoes_idx, shoes in enumerate(shoes_features):
                cnn_features = np.stack([top, selected_features, shoes])
                cnn_features = cnn_features.reshape((1, 3, -1))

                prob = comb_model.predict(cnn_features)
                score = score_model.predict([top.reshape(1, -1), selected_features.reshape(1, -1), shoes.reshape(1, -1)])

                combinations.append({
                    "top_image_url": top_images[top_idx],
                    "bottom_image_url": selected_image_url,
                    "shoes_image_url": shoes_images[shoes_idx],
                    "score": score.tolist()
                })

    elif selected_category == 'shoes':
        if not top_images or not bottom_images:
            return jsonify({"error": "Not enough items to recommend an outfit"}), 400
        
        top_features = []
        bottom_features = []
        for img_url in top_images:
            top_features.append(extract_features(download_image_from_cloudinary(img_url, 'top')))
        for img_url in bottom_images:
            bottom_features.append(extract_features(download_image_from_cloudinary(img_url, 'bottom')))
        
        combinations = []
        for top_idx, top in enumerate(top_features):
            for bottom_idx, bottom in enumerate(bottom_features):
                cnn_features = np.stack([top, bottom, selected_features])
                cnn_features = cnn_features.reshape((1, 3, -1))

                prob = comb_model.predict(cnn_features)
                score = score_model.predict([top.reshape(1, -1), bottom.reshape(1, -1), selected_features.reshape(1, -1)])

                combinations.append({
                    "top_image_url": top_images[top_idx],
                    "bottom_image_url": bottom_images[bottom_idx],
                    "shoes_image_url": selected_image_url,
                    "score": score.tolist()
                })

    # Sort combinations by score and return the top 2
    combinations.sort(key=lambda x: x['score'][0], reverse=True)
    best_combinations = combinations[:2]

    return jsonify({
        "best_combinations": best_combinations
    })






if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(host='0.0.0.0', port=5000, debug=True)





