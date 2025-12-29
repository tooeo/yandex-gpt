#!/bin/bash

# Test script for Yandex GPT Tags API

BASE_URL="http://localhost:8080/api/v1"

echo "=== Testing Yandex GPT Tags API ==="
echo ""

# Test 1: Health Check
echo "1. Testing Health Check..."
curl -s "${BASE_URL}/health" | jq .
echo ""

# Test 2: Simple tags generation
echo "2. Testing simple tags generation..."
curl -s -X POST "${BASE_URL}/tags" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Building REST APIs with Golang and PostgreSQL database",
    "num_tags": 5
  }' | jq .
echo ""

# Test 3: Tags with range
echo "3. Testing tags with min/max range..."
curl -s -X POST "${BASE_URL}/tags" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "This comprehensive guide covers Docker containerization, Kubernetes orchestration, and CI/CD pipelines for microservices deployment",
    "min_tags": 3,
    "max_tags": 7
  }' | jq .
echo ""

# Test 4: Tags with existing tags
echo "4. Testing tags with existing project tags..."
curl -s -X POST "${BASE_URL}/tags" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Machine learning algorithms for computer vision and image recognition",
    "num_tags": 5,
    "existing_tags": ["ai", "machine-learning", "python", "tensorflow", "opencv"]
  }' | jq .
echo ""

# Test 5: Tags with custom prompt
echo "5. Testing tags with custom prompt..."
curl -s -X POST "${BASE_URL}/tags" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Beginner tutorial on web development",
    "num_tags": 4,
    "custom_prompt": "Focus on beginner-friendly and educational tags"
  }' | jq .
echo ""

echo "=== Tests completed ==="

