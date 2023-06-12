# https://github.com/tiangolo/uvicorn-gunicorn-fastapi-docker

FROM python:3.10-buster

# set environment variables
ENV PYTHONWRITEBYTECODE 1
ENV PYTHONBUFFERED 1
#ENV NODE_ENV postgres-db
#ENV AWS_REGION us-east-1a

# set working directory
WORKDIR /code

#RUN echo "test"

# copy dependencies
COPY requirements.txt /code/

# install dependencies
RUN pip install -r requirements.txt

# where I see the app
#EXPOSE 3000

# copy project
COPY ./app /code/app

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "80"]