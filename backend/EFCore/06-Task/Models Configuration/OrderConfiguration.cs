using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ShopManagementSystem.Models;
using System;
using System.Collections.Generic;
using System.Text;

namespace ShopManagementSystem.Models_Configration
{
    internal class OrderConfiguration : IEntityTypeConfiguration<Order>
    {
        public void Configure (EntityTypeBuilder<Order> Builder)
        {
            Builder.ToTable("Orders", "Sales");

            Builder.HasKey(p => p.Id);

            Builder.Property(p => p.CustomerEmail)
                .HasMaxLength(150)
                .IsRequired();

            Builder.Property(p => p.OrderDate)
                .HasDefaultValueSql("SYSDATETIME()")
                .IsRequired();

            Builder.HasMany(o => o.OrderDetails)
                .WithOne(od => od.Order)
                .HasForeignKey(od => od.OrderId);

        }

    }
}
