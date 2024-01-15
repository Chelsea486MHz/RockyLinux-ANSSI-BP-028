# Post-installation script
%post --erroronfail

# Set the TTY banner
echo '   ROCKY LINUX' >> /etc/issue
echo '   ANSSI-BP-028-2.0 COMPLIANT' >> /etc/issue
echo '' >> /etc/issue

# Set the SSH and cockpit banners
sed -i 's/#Banner none/Banner \/etc\/issue/g'
cp /etc/issue /etc/issue.cockpit

# Remove the cockpit message
rm -f /etc/motd.d/cockpit
rm -f /etc/issue.d/cockpit

# Enable the following services
systemctl enable sshd
systemctl enable cockpit.socket

%end
