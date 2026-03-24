# Expiration Tracker App

This project aims to study and develop a web application for managing household
ingredients and food supplies to address the issue of food waste caused by forgotten expiration
dates and unorganized storage. The system integrates Optical Character Recognition (OCR) to
automatically read expiration dates from labels and Image Classification to identify the types of
ingredients.
Regarding the current progress, the design and development of the User Interface (UI) on the
Flutter platform have been completed. This includes the Home screen for freshness status
monitoring, a Scan screen that supports two types of image uploads (labels and products), a
Review screen for data verification, and an Alerts system. For the artificial intelligence component,
EfficientNetV2B0 was selected as the core model architecture due to its high efficiency and
suitability for mobile deployment with limited resources. The training data has been prepared by
combining Food-101 for cooked food images and the Raw Food Dataset for raw ingredients.
In terms of OCR system development, experimental code has been written to benchmark the
performance of various OCR models to identify the most accurate approach. Additionally, a realworld dataset has been collected through on-site photography of actual products to serve as the
ground truth for testing. This dataset is currently in the labeling stage before being integrated into
the system to ensure it can handle the diverse variety of product labels found in Thailand.

#### Nattawadee Chaleechat
#### Saranyapong Sansit
