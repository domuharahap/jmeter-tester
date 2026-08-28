FROM alpine:3.19

# Define JMeter version
ARG JMETER_VERSION="5.6.3"
ENV JMETER_HOME /opt/apache-jmeter-${JMETER_VERSION}
ENV JMETER_BIN ${JMETER_HOME}/bin
ENV PATH ${JMETER_BIN}:${PATH}

# Install dependencies (Java is required for JMeter)
RUN apk update && \
    apk add --no-cache openjdk17-jre bash wget curl

# Download and install Apache JMeter
RUN wget https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz && \
    tar -xzf apache-jmeter-${JMETER_VERSION}.tgz -C /opt && \
    rm apache-jmeter-${JMETER_VERSION}.tgz

# Create working directory
WORKDIR /jmeter

# Copy the JMeter test script and entrypoint script
COPY dtpay-sprint-tenant-v2.0.jmx /jmeter/dtpay-testing.jmx
COPY entrypoint.sh /jmeter/entrypoint.sh

RUN chmod +x /jmeter/entrypoint.sh

# Run the entrypoint script
ENTRYPOINT ["/jmeter/entrypoint.sh"]