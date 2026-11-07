using System;
using System.Collections.Generic;
using System.Text;

namespace ShopManagementSystem.Models
{
    internal class OrderDetail
    {
        public int Id { get; set; }
        public Decimal UnitPrice { get; set; }
        public Decimal Quantity { get; set; }
        public int OrderId { get; set; }
        public int ProductId { get; set; }

        //Navigation Properties
        public Order Order { get; set; } = null!;

        public Product Product { get; set; } = null!;

    }
}
