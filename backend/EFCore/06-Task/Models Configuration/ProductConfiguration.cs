using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ShopManagementSystem.Models;
using System;
using System.Collections.Generic;
using System.Text;

namespace ShopManagementSystem.Models_Configuration
{
    internal class ProductConfiguration : IEntityTypeConfiguration<Product>
    {
        public void Configure(EntityTypeBuilder<Product> builder)
        {
            /*It's a parameter representing an instance of your Product entity,
              used inside an Expression Tree.
            */

            builder.ToTable("Products", "Inventory");
           
            builder.HasKey(p => p.Id);
            
            builder.Property(p => p.Name)
                .HasMaxLength(100)
                .IsRequired();

            builder.Property(p => p.Description)
               .HasMaxLength(500)
               .IsRequired(false);

            builder.ToTable("Products", table =>
            {
                table.HasCheckConstraint(
                    "Products_UnitPrice_CK",
                    "[UnitPrice] >= 0"
                );
            });


        }
    }
}
