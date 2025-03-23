FROM python:3.8-buster
LABEL org.opencontainers.image.authors="Ikrame Gouaiche <gouaicheikrame@gmail.com>"
COPY student_age.py /
RUN  apt update -y && apt install python3-dev libsasl2-dev libldap2-dev libssl-dev -y
COPY requirements.txt /
RUN pip3 install -r requirements.txt
RUN mkdir /data
VOLUME ["/data"]
EXPOSE 5000
CMD ["python3", "student_age.py"]