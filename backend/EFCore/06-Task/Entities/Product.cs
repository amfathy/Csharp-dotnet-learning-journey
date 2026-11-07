using System;
using System.Collections.Generic;
using System.Text;

namespace ShopManagementSystem.Models
{
    internal class Product
    {
        public int Id { get; set; }
        public string? Name { get; set; }
        public Decimal UnitPrice { get; set; }
        public string? Description { get; set; }

        //Navigation Properties
        public ICollection<OrderDetail>
            OrderDetails { get; set; } = new List<OrderDetail>(); 

    }
}
