<?php

namespace App\Twig\Extension;

use Twig\Extension\AbstractExtension;
use Twig\TwigFilter;
use App\Twig\Extension\TimeExtensionRuntime;

class TimeExtension extends AbstractExtension
{
    public function getFilters(): array
    {
        return [
            new TwigFilter('ago', [TimeExtensionRuntime::class, 'timeAgo']),
        ];
    }
}
