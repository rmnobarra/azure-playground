using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using System;
using System.IO;
using Azure.Identity;
using System.Threading.Tasks;
using Azure.Core.Diagnostics;
using System.Diagnostics.Tracing;


class Program
{
    static async Task Main(string[] args)
    {
        using AzureEventSourceListener listener = AzureEventSourceListener.CreateConsoleLogger(EventLevel.Verbose);

        // Get Storage Account Name
        string? storageAcctName = Environment.GetEnvironmentVariable("STORAGE_ACCT_NAME");
        string? containerName = Environment.GetEnvironmentVariable("CONTAINER_NAME");

        if (string.IsNullOrEmpty(storageAcctName) || string.IsNullOrEmpty(containerName))
        {
            Console.WriteLine("Storage Account or Container Name are null or empty");
            Environment.Exit(0);
        }

        while (true)
        {
            await MainAsync(storageAcctName, containerName);
            await Task.Delay(5000);
        }
    }

    static async Task MainAsync(string storageAcctName, string containerName)
    {
        var blobServiceClient = new BlobServiceClient(
                new Uri($"https://{storageAcctName}.blob.core.windows.net"),
                new DefaultAzureCredential());

        BlobContainerClient containerClient = blobServiceClient.GetBlobContainerClient(containerName);

        // Create a local file in the ./data/ directory for uploading and downloading
        string localPath = "data";
        Directory.CreateDirectory(localPath);
        string fileName = $"{Guid.NewGuid()}.txt";
        string localFilePath = Path.Combine(localPath, fileName);

        // Write text to the file
        await File.WriteAllTextAsync(localFilePath, "Hello, World!");

        // Get a reference to a blob
        BlobClient blobClient = containerClient.GetBlobClient(fileName);

        Console.WriteLine($"Uploading to Blob storage as blob:\n\t {blobClient.Uri}\n");

        // Upload data from the local file
        await blobClient.UploadAsync(localFilePath, true);
    }
}