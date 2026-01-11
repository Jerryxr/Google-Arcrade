#!/bin/bash
set -e

# ==============================
# Google Cloud Pub/Sub Lab Script
# ==============================

# Default variables
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [[ -z "$PROJECT_ID" ]]; then
  echo "❌ No active GCP project found."
  echo "Run: gcloud config set project YOUR_PROJECT_ID"
  exit 1
fi

echo "Using Project: $PROJECT_ID"
echo

# 1️⃣ Check authentication
echo "=== Listing Authentication Accounts ==="
gcloud auth list
echo

# 2️⃣ Check current project
echo "=== Current Project Configuration ==="
gcloud config list project
echo

# 3️⃣ Create topics
echo "=== Creating Pub/Sub Topics ==="
gcloud pubsub topics create myTopic
gcloud pubsub topics create Test1
gcloud pubsub topics create Test2
echo

# 4️⃣ List topics
echo "=== Listing Topics ==="
gcloud pubsub topics list
echo

# 5️⃣ Delete temporary topics
echo "=== Deleting Topics Test1 and Test2 ==="
gcloud pubsub topics delete Test1 || echo "Test1 does not exist"
gcloud pubsub topics delete Test2 || echo "Test2 does not exist"
echo

# 6️⃣ List topics again
echo "=== Topics after deletion ==="
gcloud pubsub topics list
echo

# 7️⃣ Create subscriptions
echo "=== Creating Subscriptions for myTopic ==="
gcloud pubsub subscriptions create mySubscription --topic myTopic
gcloud pubsub subscriptions create Test1 --topic myTopic
gcloud pubsub subscriptions create Test2 --topic myTopic
echo

# 8️⃣ List subscriptions of myTopic
echo "=== Listing Subscriptions of myTopic ==="
gcloud pubsub topics list-subscriptions myTopic
echo

# 9️⃣ Delete temporary subscriptions
echo "=== Deleting Subscriptions Test1 and Test2 ==="
gcloud pubsub subscriptions delete Test1 || echo "Test1 subscription does not exist"
gcloud pubsub subscriptions delete Test2 || echo "Test2 subscription does not exist"
echo

# 10️⃣ List subscriptions again
echo "=== Subscriptions after deletion ==="
gcloud pubsub topics list-subscriptions myTopic
echo

# 11️⃣ Publish messages to myTopic
echo "=== Publishing Messages to myTopic ==="
gcloud pubsub topics publish myTopic --message "Hello"
gcloud pubsub topics publish myTopic --message "Publisher's name is JerryTheMouse"
gcloud pubsub topics publish myTopic --message "Publisher likes to eat Cheeseee"
gcloud pubsub topics publish myTopic --message "Publisher thinks Pub/Sub is awesome"
echo

# 12️⃣ Pull messages from mySubscription
echo "=== Pulling Messages from mySubscription ==="
gcloud pubsub subscriptions pull mySubscription --auto-ack
echo

# 13️⃣ Publish more messages
echo "=== Publishing More Messages ==="
gcloud pubsub topics publish myTopic --message "Publisher is starting to get the hang of Pub/Sub"
gcloud pubsub topics publish myTopic --message "Publisher wonders if all messages will be pulled"
gcloud pubsub topics publish myTopic --message "Publisher will have to test to find out"
echo

# 14️⃣ Pull a limited number of messages
echo "=== Pulling 3 Messages from mySubscription ==="
gcloud pubsub subscriptions pull mySubscription --limit=3
echo

echo "✅ Pub/Sub Lab Completed Successfully!"

