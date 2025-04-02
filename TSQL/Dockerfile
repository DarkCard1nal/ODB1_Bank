# Use an official image MS SQL Server 2022
FROM mcr.microsoft.com/mssql/server:2022-latest

#Set the working directory and copy files
WORKDIR /app
COPY *.SQL .

# Configure environment variables to accept the license agreement and set the SA password
ENV ACCEPT_EULA=N
ENV SA_PASSWORD=YourStrongPassword

# Opening the port 1433
EXPOSE 1433
