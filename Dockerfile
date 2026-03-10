FROM node:20-slim

# Set working directory
WORKDIR /app

# Copy configuration
COPY package.json ./

# Install dependencies (ignoring lockfiles as per instructions)
RUN npm install

# Copy source code
COPY . .

# Run tests by default
CMD ["npm", "test"]