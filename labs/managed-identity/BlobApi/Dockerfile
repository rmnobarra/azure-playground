# Usar a imagem base do .NET SDK para buildar a aplicação
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

# Copiar o arquivo .csproj e restaurar as dependências
COPY *.csproj ./
RUN dotnet restore

# Copiar o resto do código do aplicativo e buildar
COPY . ./
RUN dotnet publish -c Release -o /out

# Usar uma imagem base menor para a execução do aplicativo
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app

# Copiar os arquivos buildados da etapa anterior
COPY --from=build /out ./

# Expor a porta configurada via variável de ambiente ou padrão para 80
ENV ASPNETCORE_URLS=http://+:${PORT:-80}
EXPOSE ${PORT:-80}

# Definir o comando de entrada para executar o aplicativo
ENTRYPOINT ["dotnet", "BlobApi.dll"]
