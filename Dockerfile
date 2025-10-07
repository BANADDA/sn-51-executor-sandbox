FROM daturaai/compute-subnet-executor:latest

# Step 2: Clone the repository
RUN git clone https://github.com/Datura-ai/compute-subnet.git /app/compute-subnet
WORKDIR /app/compute-subnet

# Step 3: Install required tools
RUN chmod +x scripts/install_executor_on_ubuntu.sh && \
    sed -i 's/sudo //g' scripts/install_executor_on_ubuntu.sh && \
    echo "" | ./scripts/install_executor_on_ubuntu.sh

# Step 6: Prepare environment template
RUN cp .env.template .env
WORKDIR /app/compute-subnet/neurons/executor

# Expose default ports (configurable via .env)
EXPOSE 8080 22

# Default command (overridden by docker-compose)
CMD ["bash"]