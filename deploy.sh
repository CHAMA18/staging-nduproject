#!/bin/bash

# NDU Project Deployment Script
# Builds and deploys both user and admin applications

set -e

echo "🚀 NDU Project Deployment Script"
echo "================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first."
    exit 1
fi

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI is not installed. Please install it first:"
    echo "   npm install -g firebase-tools"
    exit 1
fi

echo -e "${BLUE}Step 1:${NC} Getting dependencies..."
flutter pub get

echo ""
echo -e "${BLUE}Step 2:${NC} Building user app..."
flutter build web --target=lib/main.dart --release --pwa-strategy=none
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ User app built successfully${NC}"
else
    echo "❌ User app build failed"
    exit 1
fi

echo ""
echo -e "${BLUE}Step 3:${NC} Building admin app..."
flutter build web --target=lib/main_admin.dart --release --output=build/admin_web/ --pwa-strategy=none
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Admin app built successfully${NC}"
else
    echo "❌ Admin app build failed"
    exit 1
fi

echo ""
echo -e "${BLUE}Step 4:${NC} Deploying to Firebase Hosting..."
firebase deploy --only hosting

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}=================================${NC}"
    echo -e "${GREEN}✓ Deployment completed successfully!${NC}"
    echo -e "${GREEN}=================================${NC}"
    echo ""
    echo -e "${YELLOW}Your apps are now live:${NC}"
    echo "  User App:  https://nduproject.com"
    echo "  Admin App: https://admin.nduproject.com"
    echo ""
else
    echo "❌ Firebase deployment failed"
    exit 1
fi
