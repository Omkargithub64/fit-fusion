import os
import numpy as np
import matplotlib.pyplot as plt
from PIL import Image
import tensorflow as tf
from tensorflow.keras.applications import EfficientNetB0
from tensorflow.keras.preprocessing import image
from tensorflow.keras.applications.efficientnet import preprocess_input
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Bidirectional, LSTM, Dense, Concatenate, Input
from tensorflow.keras.models import Model

import psutil


# tf.profiler.experimental.start('logdir')

base_model = EfficientNetB0(weights='imagenet', include_top=False, input_shape=(224, 224, 3))


def extract_features(img_path):
    img = image.load_img(img_path, target_size=(224, 224))
    img_data = image.img_to_array(img)
    img_data = np.expand_dims(img_data, axis=0)
    img_data = preprocess_input(img_data)

    features = base_model.predict(img_data)
    return features


def combination_model():
    model = Sequential()
    model.add(Bidirectional(LSTM(128, return_sequences=False, input_shape=(3, 7*7*1280))))
    model.add(Dense(128, activation='relu'))
    model.add(Dense(3, activation='softmax'))
    model.compile(optimizer='adam', loss='categorical_crossentropy', metrics=['accuracy'])
    model.save('comb_model.h5')
    return model


def outfit_scoring_model():
    input_top = Input(shape=(7*7*1280,))
    input_bottom = Input(shape=(7*7*1280,))
    input_shoes = Input(shape=(7*7*1280,))
    

    combined_features = Concatenate()([input_top, input_bottom, input_shoes])
    
    x = Dense(128, activation='relu')(combined_features)
    x = Dense(64, activation='relu')(x)
    output = Dense(1, activation='sigmoid')(x) 

    model = Model([input_top, input_bottom, input_shoes], output)
    model.compile(optimizer='adam', loss='binary_crossentropy', metrics=['accuracy'])
    model.save('outfit_scoring_model.h5')
    return model


def load_clothing_features(data_dir):
    clothing_types = ['top', 'bottom', 'shoes']
    features_dict = {}
    for ctype in clothing_types:
        folder = os.path.join(data_dir, ctype)
        feature_list = []
        for img_file in os.listdir(folder):
            img_path = os.path.join(folder, img_file)
            features = extract_features(img_path).reshape(-1)
            feature_list.append(features)
        features_dict[ctype] = np.array(feature_list)
    return features_dict


def load_image_paths(data_dir):
    clothing_types = ['top', 'bottom', 'shoes']
    paths_dict = {}
    for ctype in clothing_types:
        folder = os.path.join(data_dir, ctype)
        img_paths = []
        for img_file in os.listdir(folder):
            img_path = os.path.join(folder, img_file)
            img_paths.append(img_path)
        paths_dict[ctype] = img_paths
    return paths_dict


def display_combination(top_img, bottom_img, shoes_img):
    fig, axes = plt.subplots(1, 3, figsize=(15, 5))
    
    top = Image.open(top_img)
    axes[0].imshow(top)
    axes[0].set_title("Top")
    axes[0].axis('off')
    

    bottom = Image.open(bottom_img)
    axes[1].imshow(bottom)
    axes[1].set_title("Bottom")
    axes[1].axis('off')
    

    shoes = Image.open(shoes_img)
    axes[2].imshow(shoes)
    axes[2].set_title("Shoes")
    axes[2].axis('off')
    
    plt.show()



def generate_and_score_combinations(top_features, bottom_features, shoes_features, comb_model, score_model):
    combinations = []
    scores = []
    for top_idx, top in enumerate(top_features):
        for bottom_idx, bottom in enumerate(bottom_features):
            for shoes_idx, shoes in enumerate(shoes_features):
                
                
                cnn_features = np.stack([top, bottom, shoes])
                cnn_features = cnn_features.reshape((1, 3, -1))
                
                
                
                prob = comb_model.predict(cnn_features)
                combinations.append((top_idx, bottom_idx, shoes_idx, prob))
                
                
                score = score_model.predict([top.reshape(1, -1), bottom.reshape(1, -1), shoes.reshape(1, -1)])
                scores.append(score)
    
    return combinations, scores




def display_top_combinations(combinations, scores, paths_dict, top_n=5):

    best_combinations = sorted(zip(combinations, scores), key=lambda x: x[1], reverse=True)[:top_n]
    
    for idx, (combo, score) in enumerate(best_combinations):
        print(f"Combination {idx+1}: Probability = {combo[3]}, Score = {score}")
        

        top_img_path = paths_dict['top'][combo[0]]
        bottom_img_path = paths_dict['bottom'][combo[1]]
        shoes_img_path = paths_dict['shoes'][combo[2]]

        
        display_combination(top_img_path, bottom_img_path, shoes_img_path)




def main():
    data_dir = 'data/'
    
    clothing_features = load_clothing_features(data_dir)
    
    
    paths_dict = load_image_paths(data_dir)
    
    
    comb_model = combination_model()
    score_model = outfit_scoring_model()

    
    top_features = clothing_features['top']
    bottom_features = clothing_features['bottom']
    shoes_features = clothing_features['shoes']

    combinations, scores = generate_and_score_combinations(top_features, bottom_features, shoes_features, comb_model, score_model)
    
    
    display_top_combinations(combinations, scores, paths_dict)

if __name__ == '__main__':
    main()
    

# tf.profiler.experimental.stop()



