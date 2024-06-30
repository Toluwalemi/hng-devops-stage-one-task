# HNG Internship DevOps Stage Zero Submission

## Project Overview

This repository contains my submission for the HNG Internship stage zero task. It showcases a static website deployed using Docker Compose and NGINX to an EC2 Instance.

## Features

- **Static Content**: Includes HTML, CSS, and JavaScript files.
- **Deployment**: Uses Docker Compose for containerization and NGINX for serving static files.
- **CI/CD**: Implements GitHub Actions for automated deployment.

## Deployment Instructions

To deploy this project locally or on a cloud server (AWS EC2 or GCP VM), follow these steps:

1. Clone the repository:
   ```bash
   git clone git@github.com:Toluwalemi/hng-devops-stage-zero-task.git
   cd git@github.com:Toluwalemi/hng-devops-stage-zero-task.git

2. Build and run using Docker Compose
   ```bash
   docker-compose build
   docker-compose up -d

View the Project
View the deployed website (EC2): http://ec2-3-71-88-44.eu-central-1.compute.amazonaws.com/
View the deployed website (GCE): http://34.172.125.68/