using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;
using System.Threading.Tasks;

[ApiController]
[Route("api/[controller]")]
public class BlobsController : ControllerBase
{
    private readonly BlobServiceClient _blobServiceClient;

    public BlobsController(BlobServiceClient blobServiceClient)
    {
        _blobServiceClient = blobServiceClient;
    }

    [HttpGet]
    public async Task<IActionResult> ListBlobs()
    {
        string? containerName = Environment.GetEnvironmentVariable("CONTAINER_NAME");

        if (string.IsNullOrEmpty(containerName))
        {
            return BadRequest("A variável de ambiente CONTAINER_NAME não está definida.");
        }

        var containerClient = _blobServiceClient.GetBlobContainerClient(containerName);
        var blobs = new List<string>();

        await foreach (BlobItem blobItem in containerClient.GetBlobsAsync())
        {
            blobs.Add(blobItem.Name);
        }

        return Ok(blobs);
    }
}
