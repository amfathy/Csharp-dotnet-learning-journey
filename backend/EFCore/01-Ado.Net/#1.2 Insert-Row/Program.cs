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
            var WalletToInsert = new Wallet
            {
                Holder = "Ahmedd",
                Balance = 20000

            };
            var q1 = "INSERT INTO WALLETS (Holder , Balance) Values " +
                      $"(@Holder , @Balance) " ;


            SqlParameter holderParamter = new SqlParameter
            {
                ParameterName = "@Holder" , 
                SqlDbType = SqlDbType.VarChar , 
                Direction = ParameterDirection.Input,
                Value = WalletToInsert.Holder
            };
            SqlParameter BalanceParamter = new SqlParameter
            {
                ParameterName = "@Balance",
                SqlDbType = SqlDbType.Decimal,
                Direction = ParameterDirection.Input,
                Value = WalletToInsert.Balance
            };

            var sqlCommand = new SqlCommand(q1, connection);
            sqlCommand.Parameters.Add(holderParamter);
            sqlCommand.Parameters.Add(BalanceParamter);

            sqlCommand.CommandType = CommandType.Text;

                
            connection.Open();
            if (sqlCommand.ExecuteNonQuery() > 0)
            {
                Console.WriteLine("Successfullt added"); 
            }else
            {
                Console.WriteLine("Error");
            }
             
            connection.Close();
        }
    }
}
