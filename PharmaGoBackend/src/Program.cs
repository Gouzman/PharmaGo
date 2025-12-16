using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using PharmaGo.Application;
using PharmaGo.Cron;
using PharmaGo.Infrastructure;

var builder = WebApplication.CreateBuilder(args);

// ===============================================================
// CONFIGURATION
// ===============================================================

// Charger la configuration Supabase
var supabaseUrl = builder.Configuration["Supabase:Url"] 
    ?? throw new Exception("Supabase:Url manquant dans appsettings.json");
var supabaseKey = builder.Configuration["Supabase:Key"] 
    ?? throw new Exception("Supabase:Key manquant dans appsettings.json");

// ===============================================================
// SERVICES
// ===============================================================

// Services API
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo
    {
        Title = "PharmaGo API",
        Version = "v1",
        Description = "API pour la gestion et la diffusion des pharmacies de PharmaGo"
    });
});

// CORS pour Flutter
builder.Services.AddCors(options =>
{
    options.AddPolicy("FlutterApp", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// Services Infrastructure
builder.Services.AddSingleton<SupabaseClientService>(sp =>
{
    var service = new SupabaseClientService(supabaseUrl, supabaseKey);
    service.InitializeAsync().Wait();
    return service;
});

builder.Services.AddScoped<PharmacyRepository>();

// Services OSM
builder.Services.AddHttpClient<OverpassService>();
builder.Services.AddScoped<OsmSyncService>();

// Services Application
builder.Services.AddScoped<PharmacySyncService>();

// Services Cron (BackgroundServices)
builder.Services.AddSingleton<GuardUpdater>();
builder.Services.AddSingleton<PharmacyUpdater>();
builder.Services.AddHostedService(provider => provider.GetRequiredService<GuardUpdater>());
builder.Services.AddHostedService(provider => provider.GetRequiredService<PharmacyUpdater>());

// Logging
builder.Services.AddLogging();

// ===============================================================
// APP CONFIGURATION
// ===============================================================

var app = builder.Build();

// Configuration du pipeline HTTP
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(options =>
    {
        options.SwaggerEndpoint("/swagger/v1/swagger.json", "PharmaGo API v1");
        options.RoutePrefix = string.Empty; // Swagger à la racine
    });
}

app.UseHttpsRedirection();
app.UseCors("FlutterApp");
app.UseAuthorization();
app.MapControllers();

// ===============================================================
// STARTUP
// ===============================================================

Console.WriteLine("╔═══════════════════════════════════════════════════════╗");
Console.WriteLine("║              🏥 PharmaGo Backend API 🏥              ║");
Console.WriteLine("╚═══════════════════════════════════════════════════════╝");
Console.WriteLine();
Console.WriteLine("✅ Services configurés:");
Console.WriteLine("   • Supabase Client");
Console.WriteLine("   • Pharmacy Repository");
Console.WriteLine("   • Pharmacy Sync Service");
Console.WriteLine("   • Guard Updater (CRON quotidien à 00:00)");
Console.WriteLine("   • Pharmacy Updater (CRON toutes les 6h)");
Console.WriteLine();
Console.WriteLine("📡 Endpoints disponibles:");
Console.WriteLine("   GET  /api/pharmacies/latest        → URL du JSON");
Console.WriteLine("   GET  /api/pharmacies               → Toutes les pharmacies");
Console.WriteLine("   GET  /api/pharmacies/{id}          → Pharmacie par ID");
Console.WriteLine("   GET  /api/pharmacies/guard         → Pharmacies de garde");
Console.WriteLine("   GET  /api/pharmacies/commune/{c}   → Par commune");
Console.WriteLine("   GET  /api/pharmacies/nearby        → À proximité");
Console.WriteLine("   POST /api/pharmacies/sync          → Force sync");
Console.WriteLine("   POST /api/pharmacies/guard/update  → Force garde update");
Console.WriteLine("   GET  /api/pharmacies/health        → Santé du backend");
Console.WriteLine();
Console.WriteLine("🚀 Serveur démarré...");
Console.WriteLine();

app.Run();
