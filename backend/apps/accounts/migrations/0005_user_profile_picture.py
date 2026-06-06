from django.db import migrations, models

import apps.accounts.models


class Migration(migrations.Migration):
    dependencies = [("accounts", "0004_user_is_approved")]

    operations = [
        migrations.AddField(
            model_name="user",
            name="profile_picture",
            field=models.ImageField(
                blank=True,
                null=True,
                storage=apps.accounts.models.profile_picture_storage,
                upload_to=apps.accounts.models.user_profile_picture_path,
            ),
        ),
    ]
