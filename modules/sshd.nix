{...}:
{
    services.openssh = {
        enable = true;
        passwordAuthentication = false;
    };

    users.users.dany.openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDYQ0JDZ/JDuShkmwCWaCDsodyzJ1EcZ8iXRiC5tFlx7cLfqVVj6HVpucdOvh09iReMgBZSe5B7yNIBxvRc8gLmCzHGYgs0N8bHroeKvExG8xoHtTIeKcwohPb5TEAwmCXNvXMWEFxQkilFTFY1/hOFVDfjO5QmUw6xY3AdsjYANvOm7fguV6Pg/6zNxfDASI4UWzlBXCQvF93hO9ztF6lLvuX6N8+aApcfZCjEmrPXe1ZttFZYZRdR4JiBqJRZuC405BFPXfMLiIBb4MYU6HChb6vStIZT2mpn8j4GFEB9dGxhVFhqzMTU6hiS0FUwBXB/yJk9ieClhjxbuHt3HGyD dany@dany-pc"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDw+pKDx5WSuE/mQ/zBNWAkdRS4iM9nEDM86har7KNoYKbZ9lLcKLIQC7Y/IdFXQ4hGR/lhulPFSJATrMAeKgcZ74mSOY7bY67DI/4ND6JxI+03yTfclrmo9FV+BmQFQhoyRQYzdQ+ryFDjj7+Xf3VNOJjmIKFntORXt1hbfu/L+OvAXT73fl16XB6yUufcCiBT0AFzZsD4IXTItSVJmAClQz1YHipcLdMn6uNlUB89Umm0aYLvb6TJhAF7fsXGc6uogteP6SMJXgblXa+ai9eGPp/UkwKDm7W/ygqT/fDPEBnHpV98rxiepmO4sz/DXOJHjyJ2fUW8p7/yt4VxOtOt dany@dany-macbook-pro"
    ];
}
