using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using System.Data;

namespace UdemyCourse
{
    internal partial class Program
    {
        static void Main(string[] args)
        {
            var conf = new ConfigurationBuilder()
                .AddJsonFile("appSettings.json")
                .Build();

            //Console.WriteLine(conf.GetSection("constr").Value);

            var connection = new SqlConnection(conf.GetSection("constr").Value);

            var q1 = "Select * from Wallets"; 

            var sqlCommand = new SqlCommand(q1, connection);
            
            sqlCommand.CommandType = CommandType.Text;
            
            connection.Open(); 

            SqlDataReader reader = sqlCommand.ExecuteReader();

            Wallet wal;

            while (reader.Read())
            {
                wal = new Wallet()
                { 
                    Id = reader.GetInt32("Id") , 
                    Holder = reader.GetString("Holder"), 
                    Balance = reader.GetDecimal("Balance")
                };

               Console.WriteLine(wal.ToString());
            }
            reader.Close(); 
            connection.Close();
        }
    }
}
