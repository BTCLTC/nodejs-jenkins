FROM node:16-alpine3.14

WORKDIR /home/node/app

COPY package*.json ./

RUN npm install

COPY . ./

EXPOSE 80

CMD ["npm", "run", "start"]