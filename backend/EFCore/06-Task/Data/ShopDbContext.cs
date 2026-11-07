using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using ShopManagementSystem.Models;
using ShopManagementSystem.Models_Configuration;
using ShopManagementSystem.Read_Models;
using System;
using System.Collections.Generic;
using System.Text;

namespace ShopManagementSystem.Data
{
    internal class ShopDbContext : DbContext 
    {
        public ShopDbContext (DbContextOptions<ShopDbContext> options)
            : base(options) { }

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            base.OnConfiguring(optionsBuilder);

            var configration = new ConfigurationBuilder().AddJsonFile("appSetting.json").Build();
            var conStr = configration.GetSection("constr").Value;

            optionsBuilder.UseSqlServer(conStr);

        }


        //tables 
        public DbSet<Order> Orders => Set<Order>();
        public DbSet<Product> Products => Set<Product>(); 
        public DbSet<OrderDetail> orderDetails => Set<OrderDetail>();

        //views 
        public DbSet<OrderWithDetailsView> OrderWithDetails
        => Set<OrderWithDetailsView>();

        public DbSet<OrderBillView> OrderBill
        => Set<OrderBillView>();

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.ApplyConfigurationsFromAssembly
                (typeof(ShopDbContext).Assembly); 

            modelBuilder.Entity<OrderWithDetailsView>()
           .HasNoKey()
           .ToView("OrderWithDetailsView", "Sales");

            modelBuilder.Entity<OrderBillView>()
           .HasNoKey()
           .ToView("OrderBillView", "Sales");

        }
    }
}
