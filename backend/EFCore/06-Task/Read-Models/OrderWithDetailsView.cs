using System;
using System.Collections.Generic;
using System.Text;

namespace ShopManagementSystem.Read_Models
{
    internal class OrderWithDetailsView
    {
        public int OrderId { get; set; }

        public string CustomerEmail { get; set; } = string.Empty;

        public string ProductName { get; set; } = string.Empty;

        public decimal UnitPrice { get; set; }

        public int Quantity { get; set; }

        public decimal LineTotal { get; set; }
    }
}
