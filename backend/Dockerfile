# Use a smaller, secure base image
FROM golang:1.22-alpine AS builder

# Set the working directory
WORKDIR /app

# Copy go.mod and download dependencies
COPY go.mod ./
RUN go mod tidy

# Copy the rest of the application source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -o /main .

# Final stage
FROM alpine:latest

# Set the working directory
WORKDIR /

# Copy the binary from the builder stage
COPY --from=builder /main /main

# Expose the port the app runs on
EXPOSE 8080

# Command to run the executable
CMD ["/main"]
