using Microsoft.EntityFrameworkCore;
using ShopManagementSystem.Data;

using var context = new ShopDbContext(
    new DbContextOptions<ShopDbContext>()
);

try
{
    // 1. Test database connection
    bool canConnect = context.Database.CanConnect();

    Console.WriteLine($"Database connected: {canConnect}");
}
catch (Exception ex)
{
    Console.WriteLine($"Error: {ex.Message}");
}