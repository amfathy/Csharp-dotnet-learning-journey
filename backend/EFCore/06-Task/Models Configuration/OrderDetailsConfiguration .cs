using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Microsoft.EntityFrameworkCore.Metadata.Internal;
using ShopManagementSystem.Models;
using System;
using System.Collections.Generic;
using System.Text;

namespace ShopManagementSystem.Models_Configration
{
    internal class OrderDetailsConfiguration : IEntityTypeConfiguration<OrderDetail>
    {
        public void Configure(EntityTypeBuilder<OrderDetail> Builder)
        {
            Builder.ToTable("OrderDetail", "Sales");

            Builder.HasKey(p => p.Id);

            Builder.HasOne(od => od.Order)
                .WithMany(o => o.OrderDetails)
                .HasForeignKey(o => o.OrderId);

            Builder.HasOne(o => o.Product)
                .WithMany(P => P.OrderDetails)
                .HasForeignKey(O => O.ProductId);
            Builder.ToTable("OrderDetail", "Sales", table => {

                table.HasCheckConstraint("OrderDetails_UnitPrice_CK"
                    , "[Quantity] > 0");
                table.HasCheckConstraint("OrderDetails_Quantity_CK"
                    , "[UnitPrice] >= 0");
            });
        }

       






       
    }
}
