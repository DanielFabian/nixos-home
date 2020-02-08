{...}:
{
    services.openssh = {
        enable = true;
        passwordAuthentication = false;
    };

    users.users.dany.openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCdRYMTLjVQk+VNNPvxltUtAMnpSzpBzWOmnCC0QnIXU48wmRaVmR7pV1oDY2GJ9xhUkeBerWLx7EPtHQCtAzXJqqSpo+bJj49WKkUDoAW5460UQnL5DuRe7faFru8JGPXRsPjnmRr+H0q5RMIb3q1g0sjmNbpQfrnQWZaKpXk0jVBaXIDJ9KsY3do7scxtP55uIcJdIi2+seBaR6qNlPx9a8dzMrAVlpxeW/fgkg3cQVmH1MSuwLLQgdpi13PyQ6NSW0CwHAgTKM1jUL11ZZJ1E4eOZYx9dX/Fp5i2k6JcGVqeUocK9gRxywxAJf4FEFEGIDxoO1Ee2xwrvJNsERL7 dany@dany-pc"
    ];

    users.users.root.openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCuXgJx4MErn1A233/7nmSxFZQ/ryV3rL4lXfiRiTqI3Xz6h6+bUQRKv0n3BfVflMQNPPpGRkPlDeFdZPDFh1drSE2KTjoDhwwU9LbW2K/wn2oeuZueZ7QqDoU/FDAJGb1JNYozl2cnQsO/M7k1LUgcAw2ZWLAaRElEKnvojVpG2VdwboJzH+OIQS0aDFlE5sQJXLY2g8sLo4DEI3EL0BMq1sv0K+FOOKgslNoYLQzsrLcRAgHWB8d8JCo/wfOaZCWnb51Y1fkJzclxqZhLXAGxywZuTwKxPyA/sLoXFeTM0MXwhtFLQ1TO8KgmW4UbrvvQk+5oaEAVVa/D2fJF0xzKD2N4Fzs38xYTcNSIYS+wBxuvi4dz7ahDnxboYvIUY94MMTVtVRXXF1XoXeOtvnSZnHeYe4HcwtUYyinBykoTBiuTEH9eHY2Jv2woUW7VIMRQ+34E/YbOk7c3e+IFsQhikPvMyI/rBv1ceNNjhi10Wd/WNhsScmh+gIB1KkjrpNc= root@dany-pc"
    ];
}
