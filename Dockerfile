FROM node:22

# Copy hotel-booking-api across
RUN mkdir /hotel-booking-api

WORKDIR /hotel-booking-api

COPY ./ ./

RUN npm install

CMD npm start
