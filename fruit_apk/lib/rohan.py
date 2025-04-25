import torch
from torchvision import models, transforms
from torchvision.models.feature_extraction import create_feature_extractor
from PIL import Image
import h5py
import json
import torch.nn as nn
import os

# Set device
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print(f"Using device: {device}")

# Define transformation (must match training)
transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
])

# Load ResNet50 backbone
resnet_model = models.resnet50(weights=models.ResNet50_Weights.IMAGENET1K_V2)
for param in resnet_model.parameters():
    param.requires_grad = False

# Extract features from avgpool layer
backbone = create_feature_extractor(resnet_model, return_nodes={"avgpool": "features"}).to(device)
backbone.eval()

# Classifier input dim
INPUT_DIM = 2048

# Reconstruct classifier model from config
def reconstruct_model(params, num_classes):
    layers = []
    in_features = INPUT_DIM
    n_layers = params["n_layers"]
    use_batchnorm = params["use_batchnorm"]

    for i in range(n_layers):
        out_features = params[f"n_units_l{i}"]
        layers.append(nn.Linear(in_features, out_features))
        if use_batchnorm:
            layers.append(nn.BatchNorm1d(out_features))
        layers.append(nn.ReLU())
        layers.append(nn.Dropout(params[f"dropout_l{i}"]))
        in_features = out_features

    layers.append(nn.Linear(in_features, num_classes))
    return nn.Sequential(*layers)

# Load trained model from .h5
def load_model_from_h5(filename):
    with h5py.File(filename, "r") as f:
        config = json.loads(f.attrs["config_json"])
        params = config["params"]
        num_classes = 4
        model = reconstruct_model(params, num_classes)
        weights = f["model_weights"]
        state_dict = {k: torch.tensor(weights[k][()]) for k in weights}
        model.load_state_dict(state_dict)
    return model

# Load model
classifier_model = load_model_from_h5("dnn.h5").to(device)
classifier_model.eval()

# Class labels (optional: load from your dataset metadata)
# class_names = os.listdir("AUGMENTED_DATA_train")  # Assumes folder names = class names
class_names = ['Green', 'Ripe', 'Overripe','Decay'] 
# class_names.sort()

# Inference function
def predict_image(image_path):
    image = Image.open(image_path).convert("RGB")
    image_tensor = transform(image).unsqueeze(0).to(device)

    # Extract features
    with torch.no_grad():
        features = backbone(image_tensor)["features"]
        features = torch.flatten(features, 1)

        # Classify
        outputs = classifier_model(features)
        _, predicted = torch.max(outputs, 1)

    predicted_class = class_names[predicted.item()] if class_names else str(predicted.item())
    return predicted_class

# 🔍 Example usage:
img_path = "Decay.jpg"
prediction = predict_image(img_path)
print(f"🧠 Predicted Class: {prediction}")