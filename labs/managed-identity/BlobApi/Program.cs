using Azure.Storage.Blobs;
using Azure.Identity;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

var builder = WebApplication.CreateBuilder(args);

// Ler a porta da variável de ambiente
string? port = Environment.GetEnvironmentVariable("PORT") ?? "5000";

// Configurar o Kestrel para escutar na porta especificada
builder.WebHost.ConfigureKestrel(serverOptions =>
{
    serverOptions.ListenAnyIP(int.Parse(port));
});

// Configurar o cliente de Blob Service usando variáveis de ambiente
builder.Services.AddSingleton(x =>
{
    string? storageAcctName = Environment.GetEnvironmentVariable("STORAGE_ACCT_NAME");

    if (string.IsNullOrEmpty(storageAcctName))
    {
        throw new InvalidOperationException("A variável de ambiente STORAGE_ACCT_NAME não está definida.");
    }

    return new BlobServiceClient(
        new Uri($"https://{storageAcctName}.blob.core.windows.net"),
        new DefaultAzureCredential());
});

// Adicionar serviços de controladores
builder.Services.AddControllers();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}

app.UseHttpsRedirection();

// Removido app.UseAuthorization() porque não estamos usando autorização

app.MapControllers();

app.Run();
